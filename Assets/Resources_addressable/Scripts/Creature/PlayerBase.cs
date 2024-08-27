// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;

// public class PlayerBase : MonoBehaviour{
//     public Dictionary<string, Transform> transformDict;
//     public Dictionary<string, Vector3> playerVector;
//     public Dictionary<string, bool> enableSkills;
//     public Dictionary<string, bool> usingSkills;
//     public Dictionary<string, bool> usingSkillsInit;
//     public Dictionary<string, int> timesSkills;
//     public Dictionary<string, int> timesSkillsInit;
//     public Dictionary<string, float> speedSkillsInit;
//     public Dictionary<string, float> speedSkills;
//     public Dictionary<string, bool> touchLayers;
//     public LayerMask ground_layer;
//     PlayerMove player_move;
//     PlayerAnimation player_animation;
//     PlayerTakingDamage player_taking_damage;

//     // Start is called before the first frame update
//     void Start(){
//         init_transformDict();
//         init_enableSkills();
//         init_usingSkills();
//         init_timesSkills();
//         init_speedSkills();
//         init_touchLayers();
//         init_playerVector();
//         player_move = GetComponent<PlayerMove>();
//         player_animation = GetComponent<PlayerAnimation>();
//         player_taking_damage = GetComponent<PlayerTakingDamage>();
//     }

//     // Update is called once per frame
//     void FixedUpdate(){
//         // context
//         update_touchLayers();
//         update_playerVector();
//         update_usingSkills();
//         update_timesSkills();

//         // input
//         // float input_x = Input.GetAxis("Horizontal");
//         float input_x = 0f;
//         bool keydown_jump = Input.GetKey(KeyCode.Space);
        
//         // move
//         action_stand(input_x);
//         action_move(input_x);
//         action_jump(keydown_jump, input_x);
//         action_animation(input_x, keydown_jump);
//         // if (input_x > 0){
//         //     print("");
//         // }
//     }

//     void init_transformDict(){
//         transformDict = new Dictionary<string, Transform>();
//         Transform[] childrens_transform = GetComponentsInChildren<Transform>(true);
//         foreach(Transform children in childrens_transform) transformDict.Add(children.name, children);
//     }

//     void init_playerVector(){
//         playerVector = new Dictionary<string, Vector3>();
//         playerVector.Add("position_current", transform.position);
//         playerVector.Add("position_change", transform.position);
//         playerVector.Add("velocity_current", transform.position);
//     }
//     void update_playerVector(){
//         playerVector["position_change"] = transform.position - playerVector["position_current"];
//         playerVector["position_current"] = transform.position;
//         playerVector["velocity_current"] = playerVector["position_change"] / Time.deltaTime;
//     }

//     void init_enableSkills(){
//         enableSkills = new Dictionary<string, bool>();
//         enableSkills.Add("stand", true);
//         enableSkills.Add("jump", true);
//         enableSkills.Add("jump_wall", true);
//         enableSkills.Add("move", true);
//         enableSkills.Add("slide_wall", true);
//     }    
//     public IEnumerator reverse_enableSkills(float delay_time, params string[] skills){
//         for (int i = 0; i < 2; i++){
//             foreach (string skill in skills){
//                 enableSkills[skill] = !enableSkills[skill];
//             }
//             yield return new WaitForSeconds(delay_time);
//         }
//     }
    
//     void init_usingSkills(){
//         usingSkillsInit = new Dictionary<string, bool>();
//         usingSkillsInit.Add("stand", false);
//         usingSkillsInit.Add("jump", false);
//         usingSkillsInit.Add("jump_wall", false);
//         usingSkillsInit.Add("move", false);
//         usingSkillsInit.Add("slide_wall", false);

//         usingSkills = new Dictionary<string, bool>(usingSkillsInit);
//     }    
//     public void use_skill(params string[] skills){
//         usingSkills = new Dictionary<string, bool>(usingSkillsInit);
//         foreach (string skill in skills){
//             usingSkills[skill] = true;
//         }
//     }
//     void update_usingSkills(){
//         foreach (KeyValuePair<string, bool> enableSkill in enableSkills){
//             if (!enableSkill.Value) usingSkills[enableSkill.Key] = false;
//         }
//     }

//     void init_timesSkills(){
//         timesSkillsInit = new Dictionary<string, int>();
//         timesSkillsInit.Add("jump", -2);
//         timesSkillsInit.Add("jump_wall", -2);
//         timesSkillsInit.Add("move", -1);
//         timesSkillsInit.Add("slide_wall", -1);

//         timesSkills = new Dictionary<string, int>();
//         recover_timesSkills("jump",
//                      "jump_wall",
//                      "move",
//                      "slide_wall");
//     }
//     public void recover_timesSkills(params string[] skills){
//         foreach (string skill in skills){
//             timesSkills[skill] = timesSkillsInit[skill];
//         }
//     }
//     public bool consume_timesSkill(string skill){
//         // skill unlimited?
//         if (timesSkills[skill] < 0) return true;
//         // skill avaliable?
//         else if (timesSkills[skill] == 0) return false;
//         // consume skill times
//         timesSkills[skill] -= 1;
//         return true;
//     }
//     void update_timesSkills(){
//         if (touchLayers["ground"]){
//             recover_timesSkills("move", "jump", "jump_wall", "slide_wall");
//         }
//     }

//     void init_speedSkills(){
//         speedSkillsInit = new Dictionary<string, float>();
//         speedSkillsInit.Add("move_final", 5);
//         speedSkillsInit.Add("jump_final", 5);
//         speedSkillsInit.Add("slide_wall_final", 1);
//         speedSkillsInit.Add("jump_wall_final", 5);

//         speedSkills = new Dictionary<string, float>();
//         recover_speedSkills("move_final",
//                             "jump_final",
//                             "slide_wall_final",
//                             "jump_wall_final");
//     }
//     public void recover_speedSkills(params string[] skills){
//         foreach (string skill in skills){
//             speedSkills[skill] = speedSkillsInit[skill];
//         }
//     }

//     public void init_touchLayers(){
//         touchLayers = new Dictionary<string, bool>();
//         touchLayers.Add("ground", false);
//         touchLayers.Add("wall", false);
//     }
//     public void update_touchLayers(){
//         touchLayers["ground"] = check_touch(transformDict["FootTouch"].GetComponent<EdgeCollider2D>());
//         touchLayers["wall"] = check_touch(transformDict["MiddleTouch"].GetComponent<EdgeCollider2D>());
//     }
//     public bool check_touch(Collider2D coll){
//         if (coll.IsTouchingLayers(ground_layer)) return true;
//         else return false;
//     }
    
//     public void action_stand(float input_x){
//         player_move.action_stand(input_x);
//     }

//     public void action_move(float input_x){
//         player_move.action_move(input_x);
//     }

//     public void action_jump(bool keydown_space, float input_x){
//         player_move.action_jump(keydown_space, input_x);
//     }

//     public void action_taking_damage(){
//         player_taking_damage.action_taking_damage();
//     }

//     public void action_animation(float input_x, bool keydown_jump){
//         player_animation.action_animation(input_x, keydown_jump);
//     }


// }
