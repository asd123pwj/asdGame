using TMPro;
using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine.EventSystems;
using System;

public delegate void UIInit();

public class UIIndividual : MonoBehaviour{
    // ---------- System Tools ----------
    public HierarchySearch _HierSearch;
    public InputSystem _InputSys { get { return _HierSearch._InputSys; } }
    public UISystem _UISys { get { return _HierSearch._UISys; } }
    // ---------- Sub Tools ----------
    public UIBase _Base;
    // ---------- Status ----------
    public bool _isInit = true;


    void Start(){
        _HierSearch = GameObject.Find("System").GetComponent<HierarchySearch>();
    }

    void Update(){
        init();
        _Base._update();
    }

    void init(){
        if (!_isInit) return;
        _Base._init();
        _isInit = false;
    }

    public void _destroy(){
        Destroy(gameObject);
    }
    
    public async UniTaskVoid _register_interaction(string name){
        while (_isInit) {
            Debug.Log("Waiting for init: " + _Base._name);
            await UniTask.Delay(100); 
        }
        _Base._InteractMgr._register_interaction(name);
    }

    public async UniTaskVoid _register_interaction(Type type){
        while (_isInit) {
            Debug.Log("Waiting for init: " + _Base._name);
            await UniTask.Delay(100); 
        }
        _Base._InteractMgr._register_interaction(type);
    }
    
    public async UniTaskVoid _register_interaction(UIInteractBase interaction){
        while (_isInit) {
            Debug.Log("Waiting for init: " + _Base._name);
            await UniTask.Delay(100); 
        }
        _Base._InteractMgr._register_interaction(interaction);
    }

    public void _unregister_interaction(string name){
        _Base._InteractMgr._register_interaction(name);
    }

    public void _unregister_interaction(Type type){
        _Base._InteractMgr._register_interaction(type);
    }
    
    public void _unregister_interaction(UIInteractBase interaction){
        _Base._InteractMgr._register_interaction(interaction);
    }

}
