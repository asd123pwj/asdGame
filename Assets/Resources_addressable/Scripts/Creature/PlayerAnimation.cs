using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerAnimation : MonoBehaviour{
    Animator animator;
    PlayerBase player_base;
    Utils utils;
    bool isFacingRight;
    // Start is called before the first frame update
    void Start(){
        player_base = GetComponent<PlayerBase>();
        utils = GetComponent<Utils>();
        animator = GetComponent<Animator>();
        isFacingRight = true;
    }

    public void action_animation(float input_x, bool keydown_jump){
        // facing direction
        action_facing_direction(input_x);
        action_x_animation();
        action_y_animation();
        // state monitor
        // foreach (KeyValuePair<string, bool> skill in player_base.usingSkills){
        //     animator.SetBool(skill.Key, skill.Value);
        // }
    }

    void action_facing_direction(float input_x){
        // better direction monitor
        if (player_base.enableSkills["move"]){
            if (input_x > 0 && !isFacingRight){
                flip_facing_direction();
            } else if (input_x < 0 && isFacingRight){
                flip_facing_direction();
            }
        } else {
            if (utils.compare_zero(player_base.playerVector["position_change"].x, '>') && !isFacingRight){
                flip_facing_direction();
            } else if (utils.compare_zero(player_base.playerVector["position_change"].x, '<') && isFacingRight){
                flip_facing_direction();
            }
        }
    }

    void flip_facing_direction(){
        transform.localScale = new Vector3(
            -transform.localScale.x,
            transform.localScale.y,
            transform.localScale.z);
        isFacingRight = !isFacingRight;
    }


    void action_x_animation(){
        animator.SetBool("stand", false);
        animator.SetBool("move", false);
        if (check_stand()) animator.SetBool("stand", true);
        else if (check_move()) animator.SetBool("move", true);
    }    
    bool check_stand(){
        // no x velocity?
        // if (!utils.compare_zero(player_base.playerVector["position_change"].x, '=')) return false;
        // no y velocity?
        // if (!utils.compare_zero(player_base.playerVector["position_change"].y, '=')) return false;
        // stand?
        if (!player_base.usingSkills["stand"]) return false;
        // touch ground?
        if (!player_base.touchLayers["ground"]) return false;
        return true;
    }

    bool check_move(){
        // // have x velocity?
        // if (player_base.playerVector["velocity_current"].x == 0) return false;
        // // no y velocity?
        // if (player_base.playerVector["velocity_current"].y != 0) return false;
        // move?
        if (!player_base.usingSkills["move"]) return false;
        // touch ground?
        if (!player_base.touchLayers["ground"]) return false;
        return true;
    }

    void action_y_animation(){
        animator.SetBool("jump", false);
        animator.SetBool("jump_wall", false);
        animator.SetBool("slide_wall", false);
        animator.SetInteger("float_direction", -2);
        if (check_jump()) animator.SetBool("jump", true);
        else if (check_jump_wall()) animator.SetBool("jump_wall", true);
        else if (check_slide_wall()) animator.SetBool("slide_wall", true);
        else if (!player_base.touchLayers["ground"]) animator.SetInteger("float_direction", get_float_direction());
    }
    bool check_jump(){
        // jump have cooldown, therefore the jump state just happen in 1 frame.
        // // keydown?
        // if (!keydown_jump) return false;
        // jumping?
        if (!player_base.usingSkills["jump"]) return false;
        // // touch ground?
        // if (!player_base.touchLayers["ground"]) return false;
        return true;
    }
    bool check_jump_wall(){
        // jump wall have cooldown, therefore the jump wall state just happen in 1 frame.
        // // keydown?
        // if (!keydown_jump) return false;
        // jumping wall?
        if (!player_base.usingSkills["jump_wall"]) return false;
        // // not touch ground?
        // if (player_base.touchLayers["ground"]) return false;
        // // touch wall?
        // if (!player_base.touchLayers["wall"]) return false;
        return true;
    }
    bool check_slide_wall(){
        if (!player_base.usingSkills["slide_wall"]) return false;
        return true;
    }
    int get_float_direction(){
        // no jump?
        if (player_base.usingSkills["jump"]) return 0;
        // no jump wall?
        if (player_base.usingSkills["jump_wall"]) return 0;
        // which y direction?
        if (utils.compare_zero(player_base.playerVector["position_change"].y, '=')) return 0;
        else if (utils.compare_zero(player_base.playerVector["position_change"].y, '>')) return 1;
        else return -1;
    }


}