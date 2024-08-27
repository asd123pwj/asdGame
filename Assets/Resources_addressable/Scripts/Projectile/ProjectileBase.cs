// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;

// public class ProjectileBase : MonoBehaviour{

//     PlayerBase player_base;
//     public GameObject hitParticle;

//     // Start is called before the first frame update
//     void Start(){
//         player_base = GameObject.FindGameObjectWithTag("Player").GetComponent<PlayerBase>();
//     }

//     // Update is called once per frame
//     void Update(){
        
//     }

//     void OnTriggerEnter2D(Collider2D hit_object){
//         // Effect on self
//         // particle effect
//         Instantiate(hitParticle, transform.position, Quaternion.identity);

//         // Effect on hitObject
//         // 'if' in the same level for hitting object at the same time, BUT HAVEN'T TEST.
//         if (hit_object.tag == "Player"){
//             player_base.action_taking_damage();
//             print("hit");
//         } 
//         if (hit_object.tag == "Block"){
//             print("hit block.");
//         }

//         // Keep or disappear
//         if (true){
//             Destroy(gameObject);
//         }
//     }
// }
