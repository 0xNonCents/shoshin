%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.constants import (
    ns_action, ns_stimulus, ns_object_state, ns_object_state_duration
)

func _object {range_check_ptr} (
        state : felt,
        counter : felt,
        stimulus : felt,
        agent_action : felt
    ) -> (
        state_nxt : felt,
        counter_nxt : felt
    ):

    #
    # Idle
    #
    if state == ns_object_state.IDLE:
        # interrupt by stimulus - priority > agent action
        if stimulus == ns_stimulus.HIT_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end
        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        # interrupt by agent action; locomotive action has lowest priority
        if agent_action == ns_action.SLASH:
            return (ns_object_state.SLASH_STA0, 0)
        end
        if agent_action == ns_action.UPSWING:
            return (ns_object_state.UPSWING, 0)
        end
        if agent_action == ns_action.SIDECUT:
            return (ns_object_state.SIDECUT, 0)
        end
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_0, 0)
        end
        if agent_action == ns_action.BLOCK:
            return (ns_object_state.BLOCK, 0)
        end
        if agent_action == ns_action.DASH_FORWARD:
            return (ns_object_state.DASH_FORWARD, 0)
        end
        if agent_action == ns_action.DASH_BACKWARD:
            return (ns_object_state.DASH_BACKWARD, 0)
        end
        if agent_action == ns_action.MOVE_FORWARD:
            return (ns_object_state.MOVE_FORWARD, 0)
        end
        if agent_action == ns_action.MOVE_BACKWARD:
            return (ns_object_state.MOVE_BACKWARD, 0)
        end

        # otherwise
        if counter == ns_object_state_duration.IDLE:
            return (ns_object_state.IDLE, 0)
        else:
            return (ns_object_state.IDLE, counter + 1)
        end
    end

    #
    # Slash
    #
    if state == ns_object_state.SLASH_STA0:
        if stimulus == ns_stimulus.HIT_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end

        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        return (ns_object_state.SLASH_STA1, 0)
    end

    if state == ns_object_state.SLASH_STA1:
        if stimulus == ns_stimulus.HIT_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end

        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        return (ns_object_state.SLASH_ATK0, 0)
    end

    if state == ns_object_state.SLASH_ATK0:
        if stimulus == ns_stimulus.CLASH_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end

        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        return (ns_object_state.SLASH_REC0, 0)
    end

    if state == ns_object_state.SLASH_REC0:
        if stimulus == ns_stimulus.HIT_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end

        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        return (ns_object_state.SLASH_REC1, 0)
    end

    if state == ns_object_state.SLASH_REC1:
        if stimulus == ns_stimulus.HIT_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end

        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        return (ns_object_state.IDLE, 0)
    end

    #
    # Hit
    #
    ## Consider the case when one combos == land another hit while opponent is in hit state
    if state == ns_object_state.HIT_0:
        return (ns_object_state.HIT_1, 0)
    end

    if state == ns_object_state.HIT_1:
        return (ns_object_state.HIT_2, 0)
    end

    if state == ns_object_state.HIT_2:
        return (ns_object_state.HIT_3, 0)
    end

    if state == ns_object_state.HIT_3:
        return (ns_object_state.IDLE, 0)
    end

    #
    # Focus
    #
    if state == ns_object_state.FOCUS_0:
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_1, 0)
        else:
            ## insufficient focus; releases punch
            return (ns_object_state.SLASH_STA1, 0)
        end
    end

    if state == ns_object_state.FOCUS_1:
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_2, 0)
        else:
            ## insufficient focus; releases punch
            return (ns_object_state.SLASH_STA1, 0)
        end
    end

    if state == ns_object_state.FOCUS_2:
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_3, 0)
        else:
            ## insufficient focus; releases punch
            return (ns_object_state.SLASH_STA1, 0)
        end
    end

    if state == ns_object_state.FOCUS_3:
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_4, 0)
        else:
            ## insufficient focus; releases punch
            return (ns_object_state.SLASH_STA1, 0)
        end
    end

    if state == ns_object_state.FOCUS_4:
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_4, 0)
        else:
            ## releases power attack
            return (ns_object_state.POWER_ATK0, 0)
        end
    end

    #
    # Power attack
    #
    if state == ns_object_state.POWER_ATK0:
        return (ns_object_state.POWER_ATK1, 0)
    end

    if state == ns_object_state.POWER_ATK1:
        if stimulus == ns_stimulus.BLOCKED:
            return (ns_object_state.KNOCKED, 0)
        end

        if stimulus == ns_stimulus.CLASH_BY_POWER:
            return (ns_object_state.HIT_0, 0)
        end

        return (ns_object_state.POWER_ATK2, 0)
    end

    if state == ns_object_state.POWER_ATK2:
        return (ns_object_state.POWER_ATK3, 0)
    end

    if state == ns_object_state.POWER_ATK3:
        if stimulus == ns_stimulus.BLOCKED:
            return (ns_object_state.KNOCKED, 0)
        end

        if stimulus == ns_stimulus.CLASH_BY_POWER:
            return (ns_object_state.HIT_0, 0)
        end

        return (ns_object_state.POWER_ATK4, 0)
    end

    if state == ns_object_state.POWER_ATK4:
        return (ns_object_state.POWER_ATK5, 0)
    end

    if state == ns_object_state.POWER_ATK5:
        if stimulus == ns_stimulus.BLOCKED:
            return (ns_object_state.KNOCKED, 0)
        end

        if stimulus == ns_stimulus.CLASH_BY_POWER:
            return (ns_object_state.HIT_0, 0)
        end

        return (ns_object_state.SLASH_REC0, 0)
    end

    #
    # Knock
    #
    if state == ns_object_state.KNOCKED:
        if counter == ns_object_state_duration.KNOCKED:
            return (ns_object_state.IDLE, 0)
        else:
            return (ns_object_state.KNOCKED, counter + 1)
        end
    end

    #
    # Block
    #
    if state == ns_object_state.BLOCK:
        if agent_action == ns_action.BLOCK:
            return (ns_object_state.BLOCK, 0)
        end

        return (ns_object_state.IDLE, 0)
    end

    #
    # Move forward
    #
    if state == ns_object_state.MOVE_FORWARD:
        # interrupt by stimulus - priority > agent action
        if stimulus == ns_stimulus.HIT_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end
        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        # interrupt by agent action; locomotive action has lowest priority
        if agent_action == ns_action.SLASH:
            return (ns_object_state.SLASH_STA0, 0)
        end
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_0, 0)
        end
        if agent_action == ns_action.BLOCK:
            return (ns_object_state.BLOCK, 0)
        end

        # continue moving forward
        if agent_action == ns_action.MOVE_FORWARD:
            if counter == ns_object_state_duration.MOVE_FORWARD:
                return (ns_object_state.MOVE_FORWARD, 0)
            else:
                return (ns_object_state.MOVE_FORWARD, counter + 1)
            end
        end

        # able to reverse direction immediately
        if agent_action == ns_action.MOVE_BACKWARD:
            return (ns_object_state.MOVE_BACKWARD, 0)
        end

        # otherwise return to idle
        return (ns_object_state.IDLE, 0)
    end

    #
    # Move backward
    #
    if state == ns_object_state.MOVE_BACKWARD:
        # interrupt by stimulus - priority > agent action
        if stimulus == ns_stimulus.HIT_BY_SLASH:
            return (ns_object_state.HIT_0, 0)
        end
        if stimulus == ns_stimulus.HIT_BY_POWER:
            return (ns_object_state.KNOCKED, 0)
        end

        # interrupt by agent action; locomotive action has lowest priority
        if agent_action == ns_action.SLASH:
            return (ns_object_state.SLASH_STA0, 0)
        end
        if agent_action == ns_action.FOCUS:
            return (ns_object_state.FOCUS_0, 0)
        end
        if agent_action == ns_action.BLOCK:
            return (ns_object_state.BLOCK, 0)
        end

        # continue moving backward
        if agent_action == ns_action.MOVE_BACKWARD:
            if counter == ns_object_state_duration.MOVE_BACKWARD:
                return (ns_object_state.MOVE_BACKWARD, 0)
            else:
                return (ns_object_state.MOVE_BACKWARD, counter + 1)
            end
        end

        # able to reverse direction immediately
        if agent_action == ns_action.MOVE_FORWARD:
            return (ns_object_state.MOVE_FORWARD, 0)
        end

        # otherwise return to idle
        return (ns_object_state.IDLE, 0)
    end

    #
    # Dash forward
    #
    if state == ns_object_state.DASH_FORWARD:
        # interruptible by agent action
        # TODO!!

        # continue dashing forward if frame count not reached yet
        if counter == ns_object_state_duration.DASH_FORWARD:
            return (ns_object_state.IDLE, 0)
        else:
            return (ns_object_state.DASH_FORWARD, counter + 1)
        end
    end

    #
    # Dash backward
    #
    if state == ns_object_state.DASH_BACKWARD:
        # interruptible by agent action
        # TODO!!

        # continue dashing forward if frame count not reached yet
        if counter == ns_object_state_duration.DASH_BACKWARD:
            return (ns_object_state.IDLE, 0)
        else:
            return (ns_object_state.DASH_BACKWARD, counter + 1)
        end
    end

    #
    # Upswing
    #
    if state == ns_object_state.UPSWING:
        if counter == ns_object_state_duration.UPSWING:
            return (ns_object_state.IDLE, 0)
        else:
            return (ns_object_state.UPSWING, counter + 1)
        end
    end

    #
    # Sidecut
    #
    if state == ns_object_state.SIDECUT:
        if counter == ns_object_state_duration.SIDECUT:
            return (ns_object_state.IDLE, 0)
        else:
            return (ns_object_state.SIDECUT, counter + 1)
        end
    end

    with_attr error_message ("Input state not recognized."):
        assert 0 = 1
    end
    return (0, 0)
end