using TMPro;
using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine.EventSystems;
using System;
using Unity.VisualScripting;

public class UIBase: BaseClass{
    // ---------- Sub Tools ----------
    public UIEvent _Event;
    public UITrigger _Trigger;
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
    public float _PixelsPerUnitMultiplier { get { return _info.PixelsPerUnitMultiplier; } set { _info.PixelsPerUnitMultiplier = value; } }
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
    public string _rightMenu_name { get { return _info.rightMenu_name; } set { _info.rightMenu_name = value; } }
    // ---------- Config ----------
    // ---------- Status ----------
    // public bool _isInit = true;
    public bool _isAvailable { get{ return _self.activeSelf; }}
    public List<UIBase> _subUIs;
    public string _messageID { get { return _info.messageID; } set { _info.messageID = value; } }
    bool allow_init = false;
    public int _runtimeID => _self.GetInstanceID();
    

    public UIBase(GameObject parent, UIInfo info=null){
        _info = UIClass._set_default(GetType().Name, info);
        _parent = parent;
        // _info.Cfg = this;
        // _sys = GameObject.Find("System").GetComponent<SystemManager>();
        create_self();
        _set_parent();
        add2UIs();
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
        // _register_message();
        _register_receiver();
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
        while (!_initDone) await UniTask.Delay(10);
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

    public virtual void _register_receiver(){}

    public void _set_parent(GameObject parent=null){
        update_parent(parent).Forget();
        update_UIMonitor(parent);
    }
    async UniTaskVoid update_parent(GameObject parent=null){
        if (parent != null) {
            _parent = parent;
            while (_rt_self == null) await UniTask.Yield();
            _rt_self.SetParent(_rt_parent);
        }
    }
    void update_UIMonitor(GameObject parent){
        if (parent != _UISys._foreground) _UISys._UIMonitor._remove_UI_fg(this);
        else _UISys._UIMonitor._add_UI_fg(this);
    }
    void add2UIs(){
        _UISys._UIMonitor._add_UI(this);
    }


    // ---------- Background ----------
    async UniTaskVoid set_background(){
        while (!_initDone) await UniTask.Delay(10);
        while (!_MatSys._check_all_info_initDone()) {
            Debug.Log("waiting for Material System init.");
            await UniTask.Delay(10);
        }
        if (_background_key == "") {
            Image img = _self.GetComponent<Image>() ?? _self.AddComponent<Image>();
            img.color = new(0, 0, 0, 0);
        }
        else {
            Image img = _self.GetComponent<Image>() ?? _self.AddComponent<Image>();
            if (_MatSys._spr._check_exist(_background_key)){
                while (!_MatSys._spr._check_loaded(_background_key)) {
                    Debug.Log("waiting for UI sprite loaded: " + _name + " - " + _background_key);
                    await UniTask.Delay(10);
                }
                img.sprite = _MatSys._spr._get_sprite(_background_key);
            }
            else{
                img.color = new(1, 1, 1, 1);
            }
            if (_info.check_PixelsPerUnitMultiplier){
                img.type = Image.Type.Sliced;
                img.pixelsPerUnitMultiplier = _PixelsPerUnitMultiplier;
            }
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
        _UISys._UIMonitor._show_UI(this);
    }
    public virtual void _enable(Vector2 pos){
        // _self.GetComponent<RectTransform>().position = pos;
        _set_pos(pos).Forget();
        _enable();
    }
    public virtual void _disable(){ 
        _self.SetActive(false); 
        _UISys._UIMonitor._hide_UI_fg(this);
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
    }
    async UniTaskVoid create_prefab(){
        while (!_MatSys._check_all_info_initDone()) {
            Debug.Log("waiting for Material System init.");
            await UniTask.Delay(10);
        }
        if (_MatSys._UIPfb._check_exist(_prefab_name)){
            while (!_MatSys._UIPfb._check_loaded(_prefab_name)) {
                Debug.Log("waiting for UI prefab loaded: " + _name + " - " + _prefab_name);
                await UniTask.Delay(10);
            }
            GameObject obj = _MatSys._UIPfb._get_pfb(_prefab_name);
            _self = UnityEngine.Object.Instantiate(obj, _parent.transform);
            _self.name = _name;
        }
        else {
            Debug.Log("UI prefab not exist: " + _background_key);
        }
    }


    public void _set_UIPos_Full()           => _set_UIPosition(new(0.0f, 0.0f), new(1.0f, 1.0f), new(0.5f, 0.5f), new(0.0f, 0.0f)); 
    public void _set_UIPos_LeftTop()        => _set_UIPosition(new(0.0f, 1.0f), new(0.0f, 1.0f), new(0.0f, 1.0f), new(0.0f, 0.0f)); 
    public void _set_UIPos_LeftMiddle()     => _set_UIPosition(new(0.0f, 0.5f), new(0.0f, 0.5f), new(0.0f, 0.5f), new(0.0f, 0.0f));
    public void _set_UIPos_LeftBottom()     => _set_UIPosition(new(0.0f, 0.0f), new(0.0f, 0.0f), new(0.0f, 0.0f), new(0.0f, 0.0f)); 
    public void _set_UIPos_MiddleTop()      => _set_UIPosition(new(0.5f, 1.0f), new(0.5f, 1.0f), new(0.5f, 1.0f), new(0.0f, 0.0f)); 
    public void _set_UIPos_MiddleMiddle()   => _set_UIPosition(new(0.5f, 0.5f), new(0.5f, 0.5f), new(0.5f, 0.5f), new(0.0f, 0.0f)); 
    public void _set_UIPos_MiddleBottom()   => _set_UIPosition(new(0.5f, 0.0f), new(0.5f, 0.0f), new(0.5f, 0.0f), new(0.0f, 0.0f)); 
    public void _set_UIPos_RightTop()       => _set_UIPosition(new(1.0f, 1.0f), new(1.0f, 1.0f), new(1.0f, 1.0f), new(0.0f, 0.0f)); 
    public void _set_UIPos_RightMiddle()    => _set_UIPosition(new(1.0f, 0.5f), new(1.0f, 0.5f), new(1.0f, 0.5f), new(0.0f, 0.0f)); 
    public void _set_UIPos_RightBottom()    => _set_UIPosition(new(1.0f, 0.0f), new(1.0f, 0.0f), new(1.0f, 0.0f), new(0.0f, 0.0f)); 
    public void _set_UIPosition(Vector2? anchorMin=null, Vector2? anchorMax=null, Vector2? pivot=null, Vector2? anchoredPosition=null){
        if (anchorMin != null) _anchorMin = anchorMin.Value;
        if (anchorMax != null) _anchorMax = anchorMax.Value;
        if (pivot != null) _pivot = pivot.Value;
        if (anchoredPosition != null) _anchoredPosition = anchoredPosition.Value;
        // _anchorMin = anchorMin; 
        // _anchorMax = anchorMax; 
        // _pivot = pivot; 
        // _anchoredPosition = anchoredPosition; 
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

    public async UniTaskVoid _set_pos(Vector2 pos){
        _disable(); // 应该能避免UI闪烁
        while (_rt_self == null) await UniTask.Yield();
        _rt_self.position = pos;
        _enable();
    }

}
