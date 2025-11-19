#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include <stdbool.h>

/**
 * Credits to https://github.com/jsitnicki/kubecon-2024-sockmap/blob/main/examples/redir-bypass/redir_bypass.bpf.c
 */
char LICENSE[] SEC("license") = "GPL";

volatile __u32 server_port = 0;

struct {
	__uint(type, BPF_MAP_TYPE_SOCKMAP);
	__uint(max_entries, 2);
	__type(key, __u32);
	__type(value, __u64);
} sock_map SEC(".maps");

/**
 * When the connection is established, add both sockets to SOCKMAP
 */
SEC("sockops")
int bpf_sockmap_handler(struct bpf_sock_ops *skops) {
	__u32 local_port = skops->local_port;
	__u32 remote_port = bpf_ntohl(skops->remote_port);
	__u32 key;
	int err;

	// IPv4 only
	if (skops->family != 2)
		return BPF_OK;

	bool is_server = (local_port == server_port);
	bool is_client = (remote_port == server_port);

	// We only care about the server and the client
	if (!is_server && !is_client)
		return BPF_OK;

	switch (skops->op) {
		// If the connection is established
		case BPF_SOCK_OPS_PASSIVE_ESTABLISHED_CB:	// server-side
		case BPF_SOCK_OPS_ACTIVE_ESTABLISHED_CB:	// client-side
			// Put server's socket in sock_map[0] and client's in sock_map[1]
			key = is_server ? 0 : 1;
			err = bpf_sock_map_update(skops, &sock_map, &key, BPF_ANY);
			if (err) {
				bpf_printk("Failed to update sockmap: %d\n", err);
			} else {
				bpf_printk("Socket added: %s (Key %d)\n",
					is_server ? "Server" : "Client", key);
			}
			break;
	}

	return BPF_OK;
}

SEC("sk_msg")
int bpf_redir_handler(struct sk_msg_md *msg) {
	__u32 key;

	if (msg->local_port == server_port) {
		// I'm server (Key 0), redirect to client (Key 1)
		key = 1;
	} else {
		key = 0;
	}

	return bpf_msg_redirect_map(msg, &sock_map, key, BPF_F_INGRESS);
}

