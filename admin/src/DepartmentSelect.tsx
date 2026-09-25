import { useState } from "react";
import type { DashboardActions } from "./Dashboard";
import { Dropdown } from "./Dropdown";

const NEW_DEPARTMENT = "__new__";

/** Department picker with an inline "new department" option. The empty value means none chosen. */
export function DepartmentSelect({
  actions,
  value,
  onChange,
}: {
  actions: DashboardActions;
  value: string;
  onChange: (id: string) => void;
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
    <Dropdown
      value={value}
      placeholder="Выберите департамент"
      options={[
        ...actions.departments.map((department) => ({ value: department.id, label: department.name })),
        { value: NEW_DEPARTMENT, label: "+ Новый департамент…", action: true },
      ]}
      onChange={(id) => (id === NEW_DEPARTMENT ? setCreating(true) : onChange(id))}
    />
  );
}
