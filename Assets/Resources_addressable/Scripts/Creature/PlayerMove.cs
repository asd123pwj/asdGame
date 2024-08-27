// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;

// public class PlayerMove : MonoBehaviour{
//     public Rigidbody2D rb;
//     PlayerBase player_base;
//     PlayerAnimation player_animation;
//     Utils utils;
//     // ObjectIndividual _object_individual;
    
    
//     // Start is called before the first frame update
//     public void Start(){
//         player_base = GetComponent<PlayerBase>();
//         rb = GetComponent<Rigidbody2D>();
//         player_animation = GetComponent<PlayerAnimation>();
//         utils = GetComponent<Utils>();
//         // _object_individual = GetComponent<ObjectIndividual>();
//     }

//     public void action_stand(float input_x){
//         // condiction
//         bool allowStand = check_stand(input_x);
//         // action
//         if (allowStand) stand();

//     }

//     bool check_stand(float input_x){
//         // touch ground?
//         if (!player_base.touchLayers["ground"]) return false;
//         // move?
//         if (input_x != 0) return false;
//         return true;
//     }

//     public void stand(){
//         // state
//         player_base.use_skill("stand");
//         // action
//         move(0f);
//     }

//     public void action_move(float input_x){
//         // condiction
//         bool allowMove = check_move(input_x);
//         bool allowSlideWall = check_slide_wall();
        
//         // action
//         if (allowMove) 
//             move(input_x, true);
//         if (allowSlideWall) slide_wall();
//     }

//     bool check_move(float input_x){
//         // input?
//         if (input_x == 0) return false;
//         // skill enable?
//         if (!player_base.enableSkills["move"]) return false;
//         // times enough?
//         if (!player_base.consume_timesSkill("move")) return false;
//         return true;
//     }

//     public void move(float input_x, bool change_state=false){
//         // state
//         if (change_state) player_base.use_skill("move");
//         // action
//         Vector2 velocity = new (input_x, 0);
//         // rb.velocity = velocity;
//         // _move._move(,  * _config._magnitude_move_speed.x);
//         // _object_individual._move._move(velocity.normalized, velocity.magnitude, rb0:rb);
//         // rb.velocity = new Vector2(input_x * player_base.speedSkills["move_final"], rb.velocity.y);
//         // rb.velocity = Vector2.right * player_base.speedSkills["move_final"] * input_x;
//     }

//     bool check_slide_wall(){
//         // skill enable?
//         if (!player_base.enableSkills["slide_wall"]) return false;
//         // not touch ground?
//         if (player_base.touchLayers["ground"]) return false;
//         // touch wall?
//         if (!player_base.touchLayers["wall"]) return false;
//         // times enough?
//         if (!player_base.consume_timesSkill("slide_wall")) return false;
//         return true;
//     }

//     public void slide_wall(){
//         // state
//         player_base.use_skill("slide_wall");
//         // action
//         rb.velocity = new Vector2(rb.velocity.x, Mathf.Clamp(rb.velocity.y, -player_base.speedSkills["slide_wall_final"], float.MaxValue));
//     }

//     public void action_jump(bool keydown_jump, float input_x){
//         // condiction
//         if (!keydown_jump) return;
//         // jump wall
//         if (check_jump_wall()){
//             // action
//             jump_wall(input_x);
//             // animation
//         }
//         // jump
//         else if (check_jump()) {
//             // action
//             jump();
//             // animation
//         }
//     }

//     bool check_jump(){
//         // skill enable?
//         if (!player_base.enableSkills["jump"]) return false;
//         // times enough?
//         if (!player_base.consume_timesSkill("jump")) return false;
//         return true;
//     }

//     public void jump(){
//         // state
//         player_base.use_skill("jump");
//         // cooldown
//         utils.cooldown(0.25f, "jump_wall", "jump");
//         // action
//         rb.velocity = new Vector2(rb.velocity.x, player_base.speedSkills["jump_final"]);
//     }

//     bool check_jump_wall(){
//         // skill enable?
//         if (!player_base.enableSkills["jump_wall"]) return false;
//         // touch ground?
//         if (player_base.touchLayers["ground"]) return false;
//         // touch wall?
//         if (!player_base.touchLayers["wall"]) return false;
//         // times enough?
//         if (!player_base.consume_timesSkill("jump_wall")) return false;
//         return true;
//     }

//     public void jump_wall(float input_x){
//         // state
//         player_base.use_skill("jump_wall");
//         // cooldown
//         utils.cooldown(0.25f, "jump_wall", "jump", "move");
//         // action
//         rb.velocity = new Vector2(rb.velocity.x, player_base.speedSkills["jump_wall_final"]);
//         move(-input_x);
//     }


// }
