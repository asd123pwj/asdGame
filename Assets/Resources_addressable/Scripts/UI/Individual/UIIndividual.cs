// using TMPro;
// using UnityEngine;
// using UnityEngine.UI;
// using System.Collections.Generic;
// using Cysharp.Threading.Tasks;
// using UnityEngine.EventSystems;
// using System;

// // public delegate void UIInit();

// public class UIIndividual: BaseClass {
//     // ---------- System Tools ----------
//     // public SystemManager _sys { get => BaseClass._sys; }
//     // public InputSystem _InputSys { get { return _sys._InputSys; } }
//     // public UISystem _UISys { get { return _sys._UISys; } }
//     // ---------- Sub Tools ----------
//     public UIBase _Base;
//     // ---------- Status ----------
//     // public bool _initDone = false;

//     public UIIndividual(UIBase UIBase){
//         _Base = UIBase;
//     }

//     // void Start(){
//     //     // _sys = GameObject.Find("System").GetComponent<SystemManager>();
//     // }

//     // void Update(){
//     //     init();
//     //     // _Base._update();
//     // }

//     public override void _init(){
//         // if (_initDone) return;
//         _Base._init();
//         // _initDone = true;
//     }

//     public void _destroy(){
//         GameObject.Destroy(_Base._self);
//     }
    
//     // public async UniTaskVoid _register_interaction(string name){
//     //     while (!_initDone) {
//     //         Debug.Log("Waiting for init: " + _Base._name);
//     //         await UniTask.Delay(100); 
//     //     }
//     //     _Base._InteractMgr._register_interaction(name);
//     // }

//     // public async UniTaskVoid _register_interaction(Type type){
//     //     while (!_initDone) {
//     //         Debug.Log("Waiting for init: " + _Base._name);
//     //         await UniTask.Delay(100); 
//     //     }
//     //     _Base._InteractMgr._register_interaction(type);
//     // }
    
//     // public async UniTaskVoid _register_interaction(UIInteractBase interaction){
//     //     while (!_initDone) {
//     //         Debug.Log("Waiting for init: " + _Base._name);
//     //         await UniTask.Delay(100); 
//     //     }
//     //     _Base._InteractMgr._register_interaction(interaction);
//     // }

//     // public void _unregister_interaction(string name){
//     //     _Base._InteractMgr._register_interaction(name);
//     // }

//     // public void _unregister_interaction(Type type){
//     //     _Base._InteractMgr._register_interaction(type);
//     // }
    
//     // public void _unregister_interaction(UIInteractBase interaction){
//     //     _Base._InteractMgr._register_interaction(interaction);
//     // }

// }
