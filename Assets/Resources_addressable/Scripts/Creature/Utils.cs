// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;

// public class Utils : MonoBehaviour{
//     public float zeroThres;
//     PlayerBase player_base;

//     // Start is called before the first frame update
//     void Start(){
//         player_base = GetComponent<PlayerBase>();
//         zeroThres = 1e-5f;
//     }

//     public bool compare_zero(float num, char opr){
//         if (opr == '=') if (num >= -zeroThres && num <= zeroThres) return true;
//         else if (opr == '>') if (num > zeroThres) return true;
//         else if (opr == '<') if (num < -zeroThres) return true;
//         return false;
//     }

//     public void cooldown(float cooldown_time, params string[] skills){
//         IEnumerator coroutine = player_base.reverse_enableSkills(cooldown_time, skills);
//         StartCoroutine(coroutine);
//     }
// }