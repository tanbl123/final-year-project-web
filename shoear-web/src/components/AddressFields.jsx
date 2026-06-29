// Reusable structured Malaysian address inputs (line 1, optional line 2,
// postcode, city, state). Used for the supplier's operational (pickup) address
// at registration and in profile management, and shaped to match the structured
// address the customer app collects, so the whole platform is consistent.
//
// Controlled: pass `value` ({ line1, line2, postcode, city, state }) and an
// `onChange` that receives the next value. `errors` is a { field: message } map.
// Constants/helpers (MY_STATES, emptyAddress, validateAddress) live in
// ./addressUtils so this file only exports the component (fast-refresh safe).
// Typing a 5-digit postcode auto-fills city + state from the offline Malaysian
// postcode dataset (postcodeLookup), mirroring the customer's address form.
import { useEffect, useRef, useState } from 'react';
import { MY_STATES } from './addressUtils';
import { lookupPostcode } from './postcodeLookup';

function AddressFields({ value, onChange, errors = {}, disabled = false, idPrefix = 'addr' }) {
  // keep the freshest value for the async postcode lookup callback
  const latest = useRef(value);
  useEffect(() => { latest.current = value; }, [value]);
  const [autofilled, setAutofilled] = useState(false);

  const cls = (key) => 'form-control' + (errors[key] ? ' is-invalid' : '');
  // editing line 1 keeps the hint; editing city/state by hand clears it
  const set = (key) => (e) => {
    if (key === 'city' || key === 'state') setAutofilled(false);
    onChange({ ...value, [key]: e.target.value });
  };

  // postcode → auto-fill city + state (postcode is authoritative, like the
  // customer form). Only applies if the postcode hasn't changed since the lookup.
  const onPostcode = (e) => {
    const postcode = e.target.value;
    setAutofilled(false);
    onChange({ ...value, postcode });
    if (/^\d{5}$/.test(postcode)) {
      lookupPostcode(postcode).then((hit) => {
        if (!hit || latest.current.postcode !== postcode) return;
        onChange({ ...latest.current, city: hit.city, state: hit.state });
        setAutofilled(true);
      });
    }
  };

  return (
    <div className="row g-2">
      <div className="col-12">
        <label htmlFor={`${idPrefix}-line1`} className="form-label small mb-1">Address line 1</label>
        <input id={`${idPrefix}-line1`} className={cls('line1')} value={value.line1}
          onChange={set('line1')} disabled={disabled}
          placeholder="Unit, street, building, area" maxLength={150} />
        {errors.line1 && <div className="invalid-feedback d-block">{errors.line1}</div>}
      </div>

      <div className="col-sm-4">
        <label htmlFor={`${idPrefix}-postcode`} className="form-label small mb-1">Postcode</label>
        <input id={`${idPrefix}-postcode`} className={cls('postcode')} value={value.postcode}
          onChange={onPostcode} disabled={disabled} inputMode="numeric" maxLength={5} placeholder="50480" />
        {errors.postcode && <div className="invalid-feedback d-block">{errors.postcode}</div>}
      </div>

      <div className="col-sm-8">
        <label htmlFor={`${idPrefix}-city`} className="form-label small mb-1">City</label>
        <input id={`${idPrefix}-city`} className={cls('city')} value={value.city}
          onChange={set('city')} disabled={disabled} maxLength={100} placeholder="Kuala Lumpur" />
        {errors.city && <div className="invalid-feedback d-block">{errors.city}</div>}
      </div>

      <div className="col-12">
        <label htmlFor={`${idPrefix}-state`} className="form-label small mb-1">State</label>
        <select id={`${idPrefix}-state`} className={'form-select' + (errors.state ? ' is-invalid' : '')}
          value={value.state} onChange={set('state')} disabled={disabled}>
          <option value="">Select a state…</option>
          {MY_STATES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        {errors.state && <div className="invalid-feedback d-block">{errors.state}</div>}
        {autofilled && <div className="form-text text-success">✓ City &amp; state filled from postcode.</div>}
      </div>
    </div>
  );
}

export default AddressFields;
