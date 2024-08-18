// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;
// using System;

// class UIAction{
//     // ---------- Config ----------
//     public string _single_key;
//     public _input_action _action;

//     public UIAction(string single_key, _input_action action){
//         _single_key = single_key;
//         _action = action;
//     }

//     public bool _act(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
//         if (keyStatus[_single_key].isFirstDown) return _action(keyPos, keyStatus); 
//         else return false;
//     }
// }


// public class InputUI{
//     // ---------- actions ----------
//     Dictionary<string, SingleAction> UIActions = new();
    
//     public InputUI(){}

//     public void _update(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
//         foreach (var action in UIActions.Values){
//             action._act(keyPos, keyStatus);
//         }
//     }

//     public void _register_action(string input_type, _input_action action){
//         if (!UIActions.ContainsKey(input_type)) 
//             UIActions.Add(input_type, new(input_type, action));
//         else 
//             UIActions[input_type] = new(input_type, action);
//     }
// }