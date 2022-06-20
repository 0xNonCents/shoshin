%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le

namespace ns_dynamics:
    const RANGE_CHECK_BOUND = 2 ** 120
    const SCALE_FP = 10**4
    const SCALE_FP_SQRT = 10**2

    const DT_FP = 10**3 # 0.1

    const MAX_VEL_MOVE_FP = 120 * SCALE_FP
    const MIN_VEL_MOVE_FP = -120 * SCALE_FP

    const MAX_VEL_DASH_FP = 600 * SCALE_FP
    const MIN_VEL_DASH_FP = -600 * SCALE_FP

    const MOVE_ACC_FP = 300 * SCALE_FP
    const DASH_ACC_FP = 3000 * SCALE_FP

    const DEACC_FP = 10000 * SCALE_FP
end

struct Stm:
    member reg0 : felt
end

namespace ns_scene:
    const X_MAX = 500
    const X_MIN = -500
    const BIGNUM = 2000
end

namespace ns_env:
    const STORM_PENALTY = 10
end

namespace ns_character_dimension:
    const BODY_HITBOX_W = 50
    const BODY_HITBOX_H = 116
    const BODY_KNOCKED_EARLY_HITBOX_W = 130
    const BODY_KNOCKED_LATE_HITBOX_W = 150
    const BODY_KNOCKED_EARLY_HITBOX_H = 125
    const BODY_KNOCKED_LATE_HITBOX_H = 50
    const SLASH_HITBOX_W = 90
    const SLASH_HITBOX_H = 90
    const SLASH_HITBOX_Y = BODY_HITBOX_H / 2

    const BODY_KNOCKED_ADJUST_W = BODY_KNOCKED_LATE_HITBOX_W - BODY_HITBOX_W
end

namespace ns_action:
    const NULL  = 0
    const SLASH = 1
    const FOCUS = 2
    const BLOCK = 3
    const MOVE_FORWARD  = 4
    const MOVE_BACKWARD = 5
    const DASH_FORWARD  = 6
    const DASH_BACKWARD = 7

    const UPSWING = 8
    const SIDECUT = 9
end

namespace ns_stimulus:
    const NULL = 0
    const HIT_BY_SLASH = 1
    const HIT_BY_POWER = 2
    const CLASH_BY_SLASH = 3
    const CLASH_BY_POWER = 4
    const BLOCKED = 5
end

namespace ns_object_state_duration:
    const IDLE = 4 # Jessica: 4
    const KNOCKED = 11
    const MOVE_FORWARD  = 5
    const MOVE_BACKWARD = 5
    const DASH_FORWARD  = 4
    const DASH_BACKWARD = 5
    const UPSWING = 4
    const SIDECUT = 4
end

namespace ns_object_state:
    const IDLE = 0

    const SLASH_STA0 = 10
    const SLASH_STA1 = 11
    const SLASH_ATK0 = 12
    const SLASH_REC0 = 13
    const SLASH_REC1 = 14

    const HIT_0 = 17
    const HIT_1 = 18
    const HIT_2 = 19
    const HIT_3 = 20

    const FOCUS_0 = 21
    const FOCUS_1 = 22
    const FOCUS_2 = 23
    const FOCUS_3 = 24
    const FOCUS_4 = 25

    const POWER_ATK0 = 26
    const POWER_ATK1 = 27
    const POWER_ATK2 = 28
    const POWER_ATK3 = 29
    const POWER_ATK4 = 30
    const POWER_ATK5 = 31

    const KNOCKED = 32

    const BLOCK = 44

    const MOVE_FORWARD = 45  # 45 - 50, 6 frames of variety

    const MOVE_BACKWARD = 51 # 51 - 56, 6 frames of variety

    const DASH_FORWARD = 57  # 57 - 61, 5 frames in sequence

    const DASH_BACKWARD = 62 # 62 - 67, 6 frames in sequence

    const UPSWING = 68 # 68 - 72, 5 frames in sequence

    const SIDECUT = 73 # 73 - 77, 5 frames in sequence
end

struct Vec2:
    member x : felt
    member y : felt
end

struct Rectangle:
    member origin : Vec2
    member dimension : Vec2
end

struct Hitboxes:
    member action : Rectangle
    member body : Rectangle
end

struct PhysicsScene:
    member agent_0 : Hitboxes
    member agent_1 : Hitboxes
end

#
# Character state
# - pos: position
# - dir: direction (1: facing right; 0: facing left)
# - int: integrity (akin to health point)
#
struct CharacterState:
    member pos : Vec2
    member vel_fp : Vec2
    member acc_fp : Vec2
    member dir : felt
    member int : felt
end

#
# Perceptibles
#
struct Perceptibles:
    member self_character_state : CharacterState
    member self_object_state : felt
    member opponent_character_state : CharacterState
    member opponent_object_state : felt
end

struct Frame:
    member agent_state : felt
    member agent_action : felt
    member agent_stm : Stm
    member object_state : felt
    member object_counter : felt
    member character_state : CharacterState
    member hitboxes : Hitboxes
    member stimulus : felt
end

struct FrameScene:
    member agent_0 : Frame
    member agent_1 : Frame
end

namespace ns_object_qualifiers:

    func is_object_in_slash_atk {range_check_ptr} (
        object_state : felt) -> (bool : felt):

        if object_state == ns_object_state.SLASH_ATK0:
            return (1)
        end

        return (0)
    end

    func is_object_in_power_atk {range_check_ptr} (
        object_state : felt) -> (bool : felt):

        if object_state == ns_object_state.POWER_ATK1:
            return (1)
        end

        if object_state == ns_object_state.POWER_ATK3:
            return (1)
        end

        if object_state == ns_object_state.POWER_ATK5:
            return (1)
        end

        return (0)
    end

    func is_object_in_hit {range_check_ptr} (
        object_state : felt) -> (bool : felt):

        if object_state == ns_object_state.HIT_0:
            return (1)
        end

        if object_state == ns_object_state.HIT_1:
            return (1)
        end

        if object_state == ns_object_state.HIT_2:
            return (1)
        end

        if object_state == ns_object_state.HIT_3:
            return (1)
        end

        return (0)
    end

    func is_object_in_knocked_early {range_check_ptr} (
        object_state : felt, object_counter) -> (bool : felt):

        if object_state != ns_object_state.KNOCKED:
            return (0)
        end

        #
        # counter <= 4
        #
        let (bool_counter_le_4) = is_le (object_counter, 4)
        if bool_counter_le_4 == 1:
            return (1)
        end

        return (0)
    end

    func is_object_in_knocked_late {range_check_ptr} (
        object_state : felt, object_counter : felt) -> (bool : felt):

        if object_state != ns_object_state.KNOCKED:
            return (0)
        end

        #
        # counter >= 5
        #
        let (bool_counter_ge_5) = is_le (5, object_counter)
        if bool_counter_ge_5 == 1:
            return (1)
        end

        return (0)
    end

    func is_object_in_block {range_check_ptr} (
        object_state : felt) -> (bool : felt):

        if object_state == ns_object_state.BLOCK:
            return (1)
        end

        return (0)
    end

    func is_object_in_upswing_atk {range_check_ptr} (
        object_state : felt, object_counter : felt) -> (bool : felt):

        if object_state != ns_object_state.UPSWING:
            return (0)
        end

        if object_counter != 2:
            return (0)
        end

        return (1)
    end

    func is_object_in_sidecut_atk {range_check_ptr} (
        object_state : felt, object_counter : felt) -> (bool : felt):

        if object_state != ns_object_state.SIDECUT:
            return (0)
        end

        if object_counter != 2:
            return (0)
        end

        return (1)
    end

end

