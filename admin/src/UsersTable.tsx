import { api, type User } from "./api";
import type { DashboardActions } from "./Dashboard";
import { DepartmentSelect } from "./DepartmentSelect";
import { formatDateTime } from "./format";
import { generatePassword } from "./password";

export function UsersTable({ actions, users }: { actions: DashboardActions; users: User[] }) {
  const { session, run } = actions;

  async function resetPassword(user: User) {
    const password = window.prompt(`Новый пароль для ${user.username} (от 8 символов):`, generatePassword());
    if (password && (await run(() => api.setPassword(session, user.id, password)))) {
      window.alert(`Пароль изменён.\nлогин: ${user.username}\nпароль: ${password}\nСтарые сессии завершены.`);
    }
  }

  function toggleBan(user: User) {
    const question = user.banned ? `Вернуть доступ ${user.username}?` : `Заблокировать ${user.username}? Сессии завершатся сразу.`;
    if (window.confirm(question)) {
      void run(() => api.setBanned(session, user.id, !user.banned));
    }
  }

  return (
    <section className="card">
      <h2>Игроки ({users.length})</h2>
      {users.length === 0 ? (
        <p className="muted">Пока никого. Создайте первый аккаунт выше.</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Имя</th>
                <th>Логин</th>
                <th>Департамент</th>
                <th>Создан</th>
                <th>Статус</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id} className={user.banned ? "banned" : ""}>
                  <td>{user.display_name}</td>
                  <td>
                    <code>{user.username}</code>
                  </td>
                  <td>
                    <DepartmentSelect
                      actions={actions}
                      value={user.department_id}
                      onChange={(id) => void run(() => api.updateUser(session, user.id, { department_id: id }))}
                    />
                  </td>
                  <td className="nowrap">{formatDateTime(user.created_at)}</td>
                  <td>{user.banned ? "заблокирован" : "активен"}</td>
                  <td className="actions">
                    <button className="secondary" onClick={() => void resetPassword(user)}>
                      Пароль
                    </button>
                    <button className={user.banned ? "secondary" : "danger"} onClick={() => toggleBan(user)}>
                      {user.banned ? "Разблокировать" : "Заблокировать"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
