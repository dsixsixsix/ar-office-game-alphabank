package main

import (
	"fmt"
	"net/netip"
	"strings"

	"github.com/heroiclabs/nakama-common/runtime"
)

// Office network: the second presence factor next to the entry code. The entry code, tasks, room
// codes and colleague picks count only when the request comes from an office address (OFFICE_NETWORKS),
// so a player who checked in and went home cannot keep playing. The address comes from Nakama: the
// connection or the first X-Forwarded-For entry. Nakama trusts that header, so its port must be
// reachable only through a proxy that overwrites it (Caddy does by default).

// officeNetworks: allowed prefixes; empty turns the check off (a warning at startup).
var officeNetworks []netip.Prefix

// parseOfficeNetworks: comma-separated CIDR prefixes or single addresses.
func parseOfficeNetworks(value string) ([]netip.Prefix, error) {
	var networks []netip.Prefix
	for _, item := range strings.Split(value, ",") {
		item = strings.TrimSpace(item)
		if item == "" {
			continue
		}
		if !strings.Contains(item, "/") {
			addr, err := netip.ParseAddr(item)
			if err != nil {
				return nil, fmt.Errorf("OFFICE_NETWORKS: %q is not an address or a CIDR prefix", item)
			}
			addr = addr.Unmap()
			networks = append(networks, netip.PrefixFrom(addr, addr.BitLen()))
			continue
		}
		prefix, err := netip.ParsePrefix(item)
		if err != nil {
			return nil, fmt.Errorf("OFFICE_NETWORKS: %q is not an address or a CIDR prefix", item)
		}
		networks = append(networks, prefix.Masked())
	}
	return networks, nil
}

// inOfficeNetwork: the address is in one of the prefixes, or the check is off.
func inOfficeNetwork(networks []netip.Prefix, ip string) bool {
	if len(networks) == 0 {
		return true
	}
	addr, err := netip.ParseAddr(ip)
	if err != nil {
		return false
	}
	addr = addr.Unmap()
	for _, prefix := range networks {
		if prefix.Contains(addr) {
			return true
		}
	}
	return false
}

func (tx *gameTx) clientIP() string {
	ip, _ := tx.ctx.Value(runtime.RUNTIME_CTX_CLIENT_IP).(string)
	return ip
}

// networkError: "" or "office_network_required" when the request comes from outside the office.
func (tx *gameTx) networkError() string {
	if inOfficeNetwork(officeNetworks, tx.clientIP()) {
		return ""
	}
	return "office_network_required"
}

// presenceError: why presence does not count now, or "" when the player is in the office.
func (tx *gameTx) presenceError() string {
	if !inOffice(tx.me.state, tx.today) {
		return "presence_required"
	}
	return tx.networkError()
}
