import { useState } from "react";
import type { DashboardActions } from "./Dashboard";

const NEW_DEPARTMENT = "__new__";

/** Department picker with an inline "new department" option. The empty value means none chosen. */
export function DepartmentSelect({
  actions,
  value,
  onChange,
  required = false,
}: {
  actions: DashboardActions;
  value: string;
  onChange: (id: string) => void;
  required?: boolean;
}) {
  const [creating, setCreating] = useState(false);
  const [name, setName] = useState("");

  async function create() {
    const department = await actions.createDepartment(name);
    if (department) {
      onChange(department.id);
      setCreating(false);
      setName("");
    }
  }

  if (creating) {
    return (
      <span className="inline-create">
        <input autoFocus placeholder="Название департамента" value={name} onChange={(e) => setName(e.target.value)} />
        <button type="button" onClick={create} disabled={!name.trim()}>
          Создать
        </button>
        <button type="button" className="link" onClick={() => setCreating(false)}>
          Отмена
        </button>
      </span>
    );
  }

  return (
    <select
      value={value}
      required={required}
      onChange={(e) => (e.target.value === NEW_DEPARTMENT ? setCreating(true) : onChange(e.target.value))}
    >
      <option value="" disabled>
        — выберите департамент —
      </option>
      {actions.departments.map((department) => (
        <option key={department.id} value={department.id}>
          {department.name}
        </option>
      ))}
      <option value={NEW_DEPARTMENT}>+ Новый департамент…</option>
    </select>
  );
}
