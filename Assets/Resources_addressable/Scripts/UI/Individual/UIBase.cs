using TMPro;
using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine.EventSystems;
using System;

public class UIBase: BaseClass{
    // ---------- System Tools ----------
    // public UIIndividual _ui;
    // public SystemManager _sys;
    // public MaterialSystem _MatSys { get { return _HierSearch._MatSys; } }
    // public InputSystem _InputSys { get { return _HierSearch._InputSys; } }
    // public UISystem _UISys { get { return _HierSearch._UISys; } }
    // ---------- Sub Tools ----------
    public UIEvent _Event;
    public UITrigger _Trigger;
    // public UIInteract _Interact;
    // public UIControl _Ctrl;
    public UIInteractionManager _InteractMgr;
    public UITag _Tag;
    // ---------- Unity ----------
    public GameObject _self, _parent;
    public RectTransform _rt_self { get { return _self.GetComponent<RectTransform>(); } }
    public RectTransform _rt_parent { get { return _parent.GetComponent<RectTransform>(); } }
    // ---------- Config ----------
    public UIInfo _info;
    public string _name { get { return _info.name; } set { _info.name = value; } }
    public string _class_name { get { return _info.base_type; } set { _info.base_type = value; } }
    public string _prefab_name { get { return _info.prefab_key; } set { _info.prefab_key = value; } }
    public string _background_key { get { return _info.background_key; } set { _info.background_key = value; } }
    
    // ----- Position
    public bool _isButtom;
    public bool _enableNavigation { get { return _info.enableNavigation; } set { _info.enableNavigation = value; } }
    public Quaternion _rotation { get { return _info.rotation; } set { _info.rotation = value; } }
    public Vector2 _anchorMin { get { return _info.anchorMin; } set { _info.anchorMin = value; } }
    public Vector2 _anchorMax { get { return _info.anchorMax; } set { _info.anchorMax = value; } }
    public Vector2 _pivot { get { return _info.pivot; } set { _info.pivot = value; } }
    public Vector2 _anchoredPosition { get { return _info.anchoredPosition; } set { _info.anchoredPosition = value; } }
    public Vector2 _sizeDelta { get { return _info.sizeDelta; } set { _info.sizeDelta = value; } }
    public Vector2 _localScale { get { return _info.localScale; } set { _info.localScale = value; } }
    // ---------- Component ----------
    public UIBase _RMenu;
    // ---------- Config ----------
    // ---------- Status ----------
    // public bool _isInit = true;
    public bool _isAvailable { get{ return _self.activeSelf; }}
    public List<UIBase> _subUIs;
    bool allow_init = false;
    // ---------- Key ----------
    // public string _subUIKey_Ctrl { get => "ControlUIs"; }
    // ---------- Extra Parameter for children class ----------
    

    public UIBase(GameObject parent, UIInfo info=null){
        _info = UIClass._set_default(GetType().Name, info);
        _parent = parent;
        // _info.Cfg = this;
        // _sys = GameObject.Find("System").GetComponent<SystemManager>();
        create_self();
        _set_parent();
        allow_init = true;
        // _ui._Base = this;
    }
    public override bool _check_allow_init(){
        return allow_init;
    }
    // public void _update(){
    // }

    // ---------- Initialization ----------
    public override void _init(){
        // ----- begin
        _init_begin();
        // ----- Background
        set_background().Forget();
        // ----- Position 
        // set_navigation();
        // ----- Sub
        init_sub_script();
        init_sub_UIs();
        init_interactions().Forget();
        // _EXTRA_init_subUIs();
        // ----- Activate
        _enable();
        // ----- Done
        _init_done();
    }

    void init_sub_script(){
        _Event = new(this);
        _Trigger = new(this);
        // _Interact = new(this);
        // _Ctrl = new(this);
        _Tag = new(this);
        _InteractMgr = new(this);
    }

    void init_sub_UIs(){
        if (_info.subUIs == null) return;
        _subUIs = new();
        foreach (var subUI in _info.subUIs){
            _subUIs.Add(UIDraw._draw_UI(_self, subUI.type, subUI)); // TODO: subUI.type -> subUI
        }
    }

     async UniTaskVoid init_interactions(){
        if (_info.interactions == null) return;
        while (!_initDone) await UniTask.Delay(100);
        foreach (var interaction in _info.interactions){
            _InteractMgr._register_interaction(interaction);
            // _ui._register_interaction(interaction).Forget();
        }
    }

    // public void _destroy(){
    //     GameObject.Destroy(_self);
    // }

    // ---------- Extra functions for children class ----------
    public virtual void _init_begin(){} 
    public virtual void _init_done(){} 

    // ---------- Status ----------
    public virtual void _update_info(){
        _rotation = _self.transform.rotation;
        _anchorMin = _rt_self.anchorMin;
        _anchorMax = _rt_self.anchorMax;
        _pivot = _rt_self.pivot;
        _anchoredPosition = _rt_self.anchoredPosition;
        _sizeDelta = _rt_self.sizeDelta;
        _localScale = _self.transform.localScale;
    }

    public void _set_parent(GameObject parent=null){
        update_parent(parent);
        update_UIMonitor();
    }
    void update_parent(GameObject parent=null){
        if (parent != null) {
            _parent = parent;
            _rt_self.SetParent(_rt_parent);
        }
    }
    void update_UIMonitor(){
        if (_parent != _UISys._foreground) _UISys._UIMonitor._remove_UI(_name);
        else _UISys._UIMonitor._add_UI(_name, this);
    }

    


    // ---------- Background ----------
    async UniTaskVoid set_background(){
        while (!_initDone) await UniTask.Delay(100);
        Image img = _self.GetComponent<Image>() ?? _self.AddComponent<Image>();
        while (!_MatSys._check_all_info_initDone()) {
            Debug.Log("waiting for Material System init.");
            await UniTask.Delay(100);
        }
        if (_MatSys._UISpr._check_exist(_background_key)){
            while (!_MatSys._UISpr._check_loaded(_background_key)) {
                Debug.Log("waiting for UI sprite loaded: " + _name + " - " + _background_key);
                await UniTask.Delay(100);
            }
            img.sprite = _MatSys._UISpr._get_spr(_background_key);
        }
        else{
            img.color = new(1, 1, 1, 1);
        }
        _apply_UIPosition();
        _apply_UIShape();
    }

    // ---------- Interacton ----------
    public virtual void _toggle(){
        if (_self.activeSelf) 
            _disable();
        else 
            _enable();
    }
    public virtual void _enable(){ 
        _self.SetActive(true); 
        _self.transform.SetAsLastSibling();
        if (_enableNavigation) 
            EventSystem.current.SetSelectedGameObject(_self);
        _UISys._UIMonitor._show_UI(_name);
    }
    public virtual void _enable(Vector2 pos){
        _self.GetComponent<RectTransform>().position = pos;
        _enable();
    }
    public virtual void _disable(){ 
        _self.SetActive(false); 
        _UISys._UIMonitor._hide_UI(_name);
    }
    public virtual void _destroy(){
        UnityEngine.Object.Destroy(_self);
    }

    void set_navigation(){
        if (!_enableNavigation) return;
        _self.AddComponent<Button>().transition = Selectable.Transition.None;
        EventSystem.current.SetSelectedGameObject(_self);
    } 
    
    // ---------- GameObject Generate ----------
    void create_self(){ 
        if (_prefab_name == "" || _prefab_name == null) 
            create_gameObject(); 
        else 
            create_prefab().Forget(); 
    }
    void create_gameObject(){ 
        _self = new(_name); 
        _self.transform.SetParent(_parent.transform, false);
        _UISys._UIMonitor._UIObj2base.Add(_self, this);
        // _ui = new(this);
        // _ui = _self.AddComponent<UIIndividual>();
    }
    async UniTaskVoid create_prefab(){
        while (!_MatSys._check_all_info_initDone()) {
            Debug.Log("waiting for Material System init.");
            await UniTask.Delay(100);
        }
        if (_MatSys._UISpr._check_exist(_background_key)){
            while (!_MatSys._UISpr._check_loaded(_background_key)) {
                Debug.Log("waiting for UI prefab loaded: " + _name + " - " + _background_key);
                await UniTask.Delay(100);
            }
            GameObject obj = _MatSys._UIPfb._get_pfb(_prefab_name);
            _self = UnityEngine.Object.Instantiate(obj, _parent.transform);
            // _self = UnityEngine.Object.Instantiate(obj);
            _self.name = _name;
            _UISys._UIMonitor._UIObj2base.Add(_self, this);
            // _ui = new(this);
            // _ui = _self.AddComponent<UIIndividual>();
        }
        else {
            Debug.Log("UI prefab not exist: " + _background_key);
        }
        // while (!_check_UIPrefab_loaded()) {
        //     Debug.Log("waiting for UI prefab loaded: " + _name);
        //     await UniTask.Delay(100);
        // }
        // GameObject obj = _MatSys._UIPfb._get_pfb(_prefab_name);
        // _self = UnityEngine.Object.Instantiate(obj, _parent.transform);
        // // _self = UnityEngine.Object.Instantiate(obj);
        // _self.name = _name;
        // _ui = _self.AddComponent<UIIndividual>();
    }


    public void _set_UIPos_Full() { 
        _set_UIPosition(new(0, 0), new(1, 1), new(0.5f, 0.5f), new(0, 0)); 
    }
    public void _set_UIPos_LeftTop() { 
        _set_UIPosition(new(0, 1), new(0, 1), new(0, 1), new(0, 0)); 
    }
    public void _set_UIPos_LeftMiddle() { 
        _set_UIPosition(new(0, 0.5f), new(0, 0.5f), new(0, 0.5f), new(0, 0));
    }
    public void _set_UIPos_LeftBottom() { 
        _set_UIPosition(new(0, 0), new(0, 0), new(0, 0), new(0, 0)); 
    }
    public void _set_UIPos_MiddleTop() { 
        _set_UIPosition(new(0.5f, 1), new(0.5f, 1), new(0.5f, 1), new(0, 0)); 
    }
    public void _set_UIPos_MiddleMiddle() { 
        _set_UIPosition(new(0.5f, 0.5f), new(0.5f, 0.5f), new(0.5f, 0.5f), new(0, 0)); 
    }
    public void _set_UIPos_MiddleBottom() { 
        _set_UIPosition(new(0.5f, 0), new(0.5f, 0), new(0.5f, 0), new(0, 0)); 
    }
    public void _set_UIPos_RightTop() { 
        _set_UIPosition(new(1, 1), new(1, 1), new(1, 1), new(0, 0)); 
    }
    public void _set_UIPos_RightMiddle() { 
        _set_UIPosition(new(1, 0.5f), new(1, 0.5f), new(1, 0.5f), new(0, 0)); 
    }
    public void _set_UIPos_RightBottom() { 
        _set_UIPosition(new(1, 0), new(1, 0), new(1, 0), new(0, 0)); 
    }
    public void _set_UIPosition(Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot, Vector2 anchoredPosition){
        _anchorMin = anchorMin; 
        _anchorMax = anchorMax; 
        _pivot = pivot; 
        _anchoredPosition = anchoredPosition; 
    }
    public void _apply_UIPosition(){
        _rt_self.anchorMin = _anchorMin; 
        _rt_self.anchorMax = _anchorMax; 
        _rt_self.pivot = _pivot; 
        _rt_self.anchoredPosition = _anchoredPosition; 
    }
    public void _apply_UIShape(){
        _rt_self.sizeDelta = _sizeDelta;
        _self.transform.rotation = _rotation;
        _rt_self.localScale = _localScale;
    }


}
