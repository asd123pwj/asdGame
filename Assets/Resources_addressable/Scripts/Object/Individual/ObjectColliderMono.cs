// using System;
// using UnityEngine;

// public class ObjectColliderMono : MonoBehaviour{
//     public static event Action<GameObject, Collision> OnCollisionEnterEvent;
//     public static event Action<GameObject, Collider> OnTriggerEnterEvent;

//     private void OnCollisionEnter(Collision collision){
//         OnCollisionEnterEvent?.Invoke(gameObject, collision);
//     }

//     private void OnTriggerEnter(Collider other){
//         OnTriggerEnterEvent?.Invoke(gameObject, other);
//     }
// }