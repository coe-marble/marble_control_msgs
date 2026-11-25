# marble_control_msgs
ROS2 control messages for marble vehicles

## Control script ROS API

| Endpoint | Type | Purpose |
| --- | --- | --- |
| `~/state` | `NumericSample` | Measurement for one named state interface. |
| `~/goal` | `NumericGoal` | Masked point update for a named reference generator, with an expiration deadline. |
| `~/command` | `NumericSample` | Final actuator values for one named command interface. |
| `~/layout` | `ControlLayout` | Measured state, actuator commands, controller contracts, and generator goal layouts. |
| `~/status` | `ControlScriptStatus` | Worker state and script failure details. |
| `~/enable` | `std_srvs/srv/SetBool` | Run control; disabling stops execution, cancels generator goals, and resets controller history. |
| `request_external_reference` | `RequestExternalReference` | Exclusively claim a named goal interface and return its reference token. |
| `release_external_reference` | `ReleaseExternalReference` | Cancel the token's goals and release its interface. |

`RequestExternalReference` now takes `interface_name` from `ControlLayout.goals`
and an introspection `identity`, replacing the legacy `ref_modes` array. Each
whole interface has one owner, and repeated claims fail even with the same
identity. `NumericGoal.identity_token` must match that interface's owner.
Goal expiry and execution disable preserve ownership; replacing the generator
revokes it. The control script node does not expose control-token services.

With `expose_navigation_topics`, `pose_ext`, `twist_ext`, and `wrench_ext` accept
the existing masked reference messages. Their token selects the claimed goal
interface; masks select x/y/z/roll/pitch/yaw. Unselected values keep their
deadlines. All accepted navigation references, including poses, have finite
timeouts. Unclaimed convenience `cmd_pos`/`cmd_vel`/`cmd_wrench` inputs cannot
overwrite a claimed interface.

Samples and goals use `interface_name`. `ControlLayout.state` and
`ControlLayout.command` list named `NumericInterface` descriptions for measurements
and final actuator commands. `ControlLayout.controllers` lists each controller's
contract, and `ControlLayout.goals` lists reference-generator names and their target
layouts. Layouts identify field offsets, widths, frames, and units through the
field's quantity. The command topic uses volatile durability.
The node starts with execution disabled. `~/enable` controls execution using active
plugins. Disabling cancels accepted generator goals and invalidates queued commands
without changing component lifecycle states. Component lifecycle services manage
plugin activation independently. The status topic reports the worker's execution state.

Each `ControlInterface` advertises flat `state`, `reference`, and `control` layouts,
plus its reference horizon length and sampling offsets. Goal expiration does not
release a controller's output ownership.

`NumericGoal.values` is one complete generator target row. An empty `update_mask` updates all
values; otherwise it contains one flag per value. True replaces that value and
its deadline, while false preserves both. A quaternion's four entries update
together. `deadline_ns` is an absolute unsigned ROS-clock time: a value expires
on the first control tick at or after that time. Unrelated values keep their own
deadlines. Goal submission timestamps are ordered independently per updated value.

`~/goal` previously accepted `NumericSample` in the measured-state layout. Publishers
must now use `NumericGoal` and select a generator from `ControlLayout.goals`.

Each state or command message contains one named interface on the existing shared
topics. These hardware-facing interfaces group fields by `resource`; fields with
no resource use their own names. The node combines state resources for the worker
and splits final actuator values for publication. Receiving a fresh sample for
one resource does not refresh another resource's timestamp or timeout.

An interface name identifies a fixed description for the node's lifetime.
Conflicting redefinitions are rejected. The advertised order remains stable
when internal buffer ordering changes.
