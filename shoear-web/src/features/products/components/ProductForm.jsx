import { useState, useEffect } from 'react';
import { fetchCategories, uploadFile } from '../productService';

// A blank size row. Suppliers add one row per size they sell.
const emptyVariant = () => ({ size: '', stock: '' });

function ProductForm({ onAdd, onCancel }) {
  const [name, setName] = useState('');
  const [brand, setBrand] = useState('');
  const [price, setPrice] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [description, setDescription] = useState('');
  const [variants, setVariants] = useState([emptyVariant()]);
  const [images, setImages] = useState([]);          // [{ url }]
  const [modelUrl, setModelUrl] = useState('');       // single .glb/.gltf
  const [modelName, setModelName] = useState('');     // shown to the supplier
  const [tryOn, setTryOn] = useState(false);

  const [categories, setCategories] = useState([]);
  const [uploading, setUploading] = useState(false);  // an upload is in flight
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchCategories()
      .then((data) => setCategories(data))
      .catch((err) => setError(err.message));
  }, []);

  // ── sizes ────────────────────────────────────────────────────────
  function updateVariant(index, field, value) {
    setVariants((prev) => prev.map((v, i) => (i === index ? { ...v, [field]: value } : v)));
  }
  function addVariantRow() {
    setVariants((prev) => [...prev, emptyVariant()]);
  }
  function removeVariantRow(index) {
    setVariants((prev) => (prev.length === 1 ? prev : prev.filter((_, i) => i !== index)));
  }

  // ── image uploads ────────────────────────────────────────────────
  async function handleImageFiles(event) {
    const files = Array.from(event.target.files);
    event.target.value = '';              // let the same file be re-picked later
    if (files.length === 0) return;

    setError('');
    setUploading(true);
    try {
      for (const file of files) {
        const { url } = await uploadFile(file, 'image');
        setImages((prev) => [...prev, { url }]);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setUploading(false);
    }
  }
  function removeImage(url) {
    setImages((prev) => prev.filter((img) => img.url !== url));
  }

  // ── 3D model upload ──────────────────────────────────────────────
  async function handleModelFile(event) {
    const file = event.target.files[0];
    event.target.value = '';
    if (!file) return;

    setError('');
    setUploading(true);
    try {
      const { url } = await uploadFile(file, 'model');
      setModelUrl(url);
      setModelName(file.name);
      setTryOn(true);                     // a model means try-on can be enabled
    } catch (err) {
      setError(err.message);
    } finally {
      setUploading(false);
    }
  }
  function removeModel() {
    setModelUrl('');
    setModelName('');
    setTryOn(false);
  }

  function resetForm() {
    setName(''); setBrand(''); setPrice(''); setCategoryId('');
    setDescription(''); setVariants([emptyVariant()]); setImages([]);
    setModelUrl(''); setModelName(''); setTryOn(false); setError('');
  }

  async function handleSubmit(event) {
    event.preventDefault();

    const cleanName = name.trim();
    const cleanBrand = brand.trim();
    const priceNumber = Number(price);

    if (cleanName === '' || cleanBrand === '') {
      setError('Name and brand cannot be empty.'); return;
    }
    if (cleanName.length > 150) { setError('Shoe name is too long (max 150 characters).'); return; }
    if (cleanBrand.length > 80) { setError('Brand is too long (max 80 characters).'); return; }
    if (Number.isNaN(priceNumber) || priceNumber <= 0) {
      setError('Price must be a number greater than 0.'); return;
    }
    if (priceNumber > 100000) { setError('Price seems too high. Please check.'); return; }
    if (categoryId === '') { setError('Please choose a category.'); return; }

    // keep only fully-filled size rows; validate the ones in progress
    const cleanVariants = [];
    const seen = new Set();
    for (const v of variants) {
      const size = v.size.trim();
      if (size === '' && v.stock === '') continue;       // ignore a fully-blank row
      if (size === '') { setError('Every size row needs a size (or clear the row).'); return; }
      if (seen.has(size.toLowerCase())) { setError(`Duplicate size: ${size}.`); return; }
      const stockNum = Number(v.stock);
      if (v.stock === '' || Number.isNaN(stockNum) || stockNum < 0 || !Number.isInteger(stockNum)) {
        setError(`Stock for size ${size} must be a whole number (0 or more).`); return;
      }
      seen.add(size.toLowerCase());
      cleanVariants.push({ size, stock: stockNum });
    }

    if (uploading) { setError('Please wait for uploads to finish.'); return; }

    setSubmitting(true);
    try {
      await onAdd({
        name: cleanName,
        brand: cleanBrand,
        price: Math.round(priceNumber * 100) / 100,
        categoryId,
        description: description.trim(),
        virtualTryOnEnable: tryOn,
        variants: cleanVariants,
        images: images.map((img) => img.url),
        modelUrl,
      });
      resetForm();
      if (onCancel) onCancel();          // close the panel after a successful add
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="card card-body mb-4 bg-light">
      <h5 className="mb-3">New product</h5>

      {error && <div className="alert alert-danger py-2">{error}</div>}

      {/* basics */}
      <div className="row g-3">
        <div className="col-md-6">
          <label className="form-label">Shoe name</label>
          <input type="text" maxLength="150" className="form-control" placeholder="e.g. Air Zoom Pegasus 40"
            value={name} onChange={(e) => setName(e.target.value)} required />
        </div>
        <div className="col-md-3">
          <label className="form-label">Brand</label>
          <input type="text" maxLength="80" className="form-control" placeholder="e.g. Nike"
            value={brand} onChange={(e) => setBrand(e.target.value)} required />
        </div>
        <div className="col-md-3">
          <label className="form-label">Price (RM)</label>
          <input type="number" min="0.01" max="100000" step="0.01" className="form-control"
            placeholder="0.00" value={price} onChange={(e) => setPrice(e.target.value)} required />
        </div>
        <div className="col-md-6">
          <label className="form-label">Category</label>
          <select className="form-select" value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)} required>
            <option value="">Choose category…</option>
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>{cat.name}</option>
            ))}
          </select>
        </div>
        <div className="col-12">
          <label className="form-label">Description</label>
          <textarea className="form-control" rows="3" maxLength="2000"
            placeholder="Materials, fit, technology, what makes this shoe special…"
            value={description} onChange={(e) => setDescription(e.target.value)} />
        </div>
      </div>

      <hr className="my-4" />

      {/* sizes & stock */}
      <div className="d-flex justify-content-between align-items-center mb-2">
        <label className="form-label mb-0 fw-semibold">Sizes &amp; stock</label>
        <button type="button" className="btn btn-outline-secondary btn-sm" onClick={addVariantRow}>
          + Add size
        </button>
      </div>
      <p className="text-muted small">Stock is tracked per size. Add a row for each size you sell.</p>
      {variants.map((v, i) => (
        <div className="row g-2 mb-2 align-items-center" key={i}>
          <div className="col-5 col-md-3">
            <input type="text" className="form-control" placeholder="Size (e.g. UK8)"
              value={v.size} onChange={(e) => updateVariant(i, 'size', e.target.value)} />
          </div>
          <div className="col-5 col-md-3">
            <input type="number" min="0" step="1" className="form-control" placeholder="Stock qty"
              value={v.stock} onChange={(e) => updateVariant(i, 'stock', e.target.value)} />
          </div>
          <div className="col-2 col-md-1">
            <button type="button" className="btn btn-outline-danger btn-sm w-100"
              disabled={variants.length === 1} onClick={() => removeVariantRow(i)} title="Remove size">
              ✕
            </button>
          </div>
        </div>
      ))}

      <hr className="my-4" />

      {/* images */}
      <label className="form-label fw-semibold">Product images</label>
      <p className="text-muted small">JPG, PNG or WebP, up to 5&nbsp;MB each.</p>
      <input type="file" className="form-control" accept="image/png,image/jpeg,image/webp"
        multiple onChange={handleImageFiles} disabled={uploading} />
      {images.length > 0 && (
        <div className="d-flex flex-wrap gap-2 mt-3">
          {images.map((img) => (
            <div key={img.url} className="position-relative">
              <img src={img.url} alt="" className="rounded border"
                style={{ width: 90, height: 90, objectFit: 'cover' }} />
              <button type="button" className="btn btn-sm btn-danger position-absolute top-0 end-0 py-0 px-1"
                style={{ transform: 'translate(30%,-30%)' }} onClick={() => removeImage(img.url)}>
                ✕
              </button>
            </div>
          ))}
        </div>
      )}

      <hr className="my-4" />

      {/* 3D model + try-on */}
      <label className="form-label fw-semibold">3D model (for AR virtual try-on)</label>
      <p className="text-muted small">A .glb or .gltf file, up to 30&nbsp;MB.</p>
      {modelUrl ? (
        <div className="d-flex align-items-center gap-2">
          <span className="badge text-bg-success">🧊 {modelName || '3D model uploaded'}</span>
          <button type="button" className="btn btn-outline-danger btn-sm" onClick={removeModel}>Remove</button>
        </div>
      ) : (
        <input type="file" className="form-control" accept=".glb,.gltf,model/gltf-binary,model/gltf+json"
          onChange={handleModelFile} disabled={uploading} />
      )}
      <div className="form-check mt-3">
        <input className="form-check-input" type="checkbox" id="tryOn"
          checked={tryOn} disabled={!modelUrl} onChange={(e) => setTryOn(e.target.checked)} />
        <label className="form-check-label" htmlFor="tryOn">
          Enable virtual try-on for this product
        </label>
      </div>

      <hr className="my-4" />

      <div className="d-flex gap-2">
        <button type="submit" className="btn btn-primary" disabled={uploading || submitting}>
          {submitting ? 'Saving…' : uploading ? 'Uploading…' : 'Save product'}
        </button>
        {onCancel && (
          <button type="button" className="btn btn-outline-secondary" onClick={onCancel}>Cancel</button>
        )}
      </div>
    </form>
  );
}

export default ProductForm;
