package main

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"sort"
	"strings"

	"github.com/heroiclabs/nakama-common/runtime"
)

// Departments are system-owned storage objects that only the server reads and writes.
// Cross-department tasks compare the players' department ids.
const (
	departmentsCollection = "departments"
	storagePageSize       = 100
	// Only the server runtime can read or write the objects.
	permissionNone = 0
	// Owner of the objects: the system user. Listing by this id skips objects a client could
	// write into the same collection under its own id.
	systemUserID = "00000000-0000-0000-0000-000000000000"
)

type Department struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type departmentValue struct {
	Name string `json:"name"`
}

// Seeded on the first start so the client's mock colleagues keep matching departments.
var defaultDepartments = []Department{
	{ID: "digital", Name: "Цифровые продукты"},
	{ID: "design", Name: "Дизайн"},
	{ID: "product_analytics", Name: "Продуктовая аналитика"},
	{ID: "hr", Name: "HR"},
	{ID: "management", Name: "Руководство"},
	{ID: "admin", Name: "Административный отдел"},
}

func listDepartments(ctx context.Context, nk runtime.NakamaModule) ([]Department, error) {
	departments := []Department{}
	cursor := ""
	for {
		objects, next, err := nk.StorageList(ctx, "", systemUserID, departmentsCollection, storagePageSize, cursor)
		if err != nil {
			return nil, errInternal
		}
		for _, object := range objects {
			var value departmentValue
			if err := json.Unmarshal([]byte(object.GetValue()), &value); err != nil {
				continue
			}
			departments = append(departments, Department{ID: object.GetKey(), Name: value.Name})
		}
		if next == "" {
			break
		}
		cursor = next
	}
	sortDepartments(departments)
	return departments, nil
}

func sortDepartments(departments []Department) {
	sort.SliceStable(departments, func(i, j int) bool {
		return strings.ToLower(departments[i].Name) < strings.ToLower(departments[j].Name)
	})
}

// nameTaken reports whether another department (not `exceptID`) already has this name.
func nameTaken(departments []Department, name, exceptID string) bool {
	for _, department := range departments {
		if department.ID != exceptID && strings.EqualFold(department.Name, name) {
			return true
		}
	}
	return false
}

func findDepartment(ctx context.Context, nk runtime.NakamaModule, id string) (Department, error) {
	if id == "" {
		return Department{}, errDepartmentNotFound
	}
	objects, err := nk.StorageRead(ctx, []*runtime.StorageRead{{Collection: departmentsCollection, Key: id, UserID: systemUserID}})
	if err != nil {
		return Department{}, errInternal
	}
	if len(objects) == 0 {
		return Department{}, errDepartmentNotFound
	}
	var value departmentValue
	if err := json.Unmarshal([]byte(objects[0].GetValue()), &value); err != nil {
		return Department{}, errInternal
	}
	return Department{ID: id, Name: value.Name}, nil
}

// writeDepartment stores a department. version "*" writes only when the key does not exist yet.
func writeDepartment(ctx context.Context, nk runtime.NakamaModule, department Department, version string) error {
	value, err := json.Marshal(departmentValue{Name: department.Name})
	if err != nil {
		return errInternal
	}
	_, err = nk.StorageWrite(ctx, []*runtime.StorageWrite{{
		Collection:      departmentsCollection,
		Key:             department.ID,
		UserID:          systemUserID,
		Value:           string(value),
		Version:         version,
		PermissionRead:  permissionNone,
		PermissionWrite: permissionNone,
	}})
	return err
}

func seedDepartments(ctx context.Context, nk runtime.NakamaModule) error {
	existing, err := listDepartments(ctx, nk)
	if err != nil || len(existing) > 0 {
		return err
	}
	for _, department := range defaultDepartments {
		if err := writeDepartment(ctx, nk, department, "*"); err != nil {
			return err
		}
	}
	return nil
}

func newDepartmentID() (string, error) {
	bytes := make([]byte, 4)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return "dep_" + hex.EncodeToString(bytes), nil
}

// rpcListDepartments: any signed-in user. Response {"departments": [{id, name}]}.
func rpcListDepartments(ctx context.Context, _ runtime.Logger, _ *sql.DB, nk runtime.NakamaModule, _ string) (string, error) {
	if _, err := callerID(ctx); err != nil {
		return "", err
	}
	departments, err := listDepartments(ctx, nk)
	if err != nil {
		return "", err
	}
	return encodeResponse(map[string]any{"departments": departments})
}

// rpcAdminCreateDepartment: {"name"} -> the new department.
func rpcAdminCreateDepartment(ctx context.Context, logger runtime.Logger, _ *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	if err := requireAdmin(ctx, nk); err != nil {
		return "", err
	}
	var request struct {
		Name string `json:"name"`
	}
	if err := decodePayload(payload, &request); err != nil {
		return "", err
	}
	name, err := normalizeName(request.Name)
	if err != nil {
		return "", err
	}
	departments, err := listDepartments(ctx, nk)
	if err != nil {
		return "", err
	}
	if nameTaken(departments, name, "") {
		return "", errDepartmentExists
	}
	id, err := newDepartmentID()
	if err != nil {
		return "", errInternal
	}
	department := Department{ID: id, Name: name}
	if err := writeDepartment(ctx, nk, department, "*"); err != nil {
		logger.Error("create department %q: %v", name, err)
		return "", errInternal
	}
	logger.Info("department %s created: %q", id, name)
	return encodeResponse(department)
}

// rpcAdminRenameDepartment: {"id", "name"} -> the renamed department.
func rpcAdminRenameDepartment(ctx context.Context, logger runtime.Logger, _ *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	if err := requireAdmin(ctx, nk); err != nil {
		return "", err
	}
	var request struct {
		ID   string `json:"id"`
		Name string `json:"name"`
	}
	if err := decodePayload(payload, &request); err != nil {
		return "", err
	}
	name, err := normalizeName(request.Name)
	if err != nil {
		return "", err
	}
	if _, err := findDepartment(ctx, nk, request.ID); err != nil {
		return "", err
	}
	departments, err := listDepartments(ctx, nk)
	if err != nil {
		return "", err
	}
	if nameTaken(departments, name, request.ID) {
		return "", errDepartmentExists
	}
	department := Department{ID: request.ID, Name: name}
	if err := writeDepartment(ctx, nk, department, ""); err != nil {
		logger.Error("rename department %s: %v", request.ID, err)
		return "", errInternal
	}
	return encodeResponse(department)
}
