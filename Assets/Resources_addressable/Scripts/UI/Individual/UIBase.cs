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
    public RectTransform _rt_self { get { return _self != null ? _self.GetComponent<RectTransform>() : null; } }
    public RectTransform _rt_parent { get { return _parent != null ? _parent.GetComponent<RectTransform>() : null; } }
    // ---------- Config ----------
    public UIInfo _info;
    // ---------- Component ----------
    public UIBase _RMenu;
    // ---------- Status ----------
    public bool _isAvailable { get{ return _self.activeSelf; }}
    public List<UIBase> _subUIs;
    bool allow_init = false;
    List<string> essential_interactions = new() { nameof(UISetTop), nameof(UILogPointerOverUI) };


    public UIBase(GameObject parent, UIInfo info=null){
        _info = UIClass._set_default(GetType().Name, info);
        _parent = parent;
        create_self();
        _set_parent(_parent);
        add2UIs();
        allow_init = true;
    }
    public override bool _check_allow_init(){
        return allow_init;
    }

    // ---------- Initialization ----------
    public override void _init(){
        // ----- begin
        _init_begin();
        // ----- Background
        set_background().Forget();
        // ----- Sub
        init_sub_script();
        init_sub_UIs();
        init_interactions().Forget();
        _register_receiver();
        // ----- Activate
        _enable();
        // ----- Done
        _init_done();
    }

    void init_sub_script(){
        _Event = new(this);
        _Trigger = new(this);
        _Tag = new(this);
        _InteractMgr = new(this);
    }

    void init_sub_UIs(){
        if (_info.subUIs == null) return;
        _subUIs = new();
        
        for(int i = 0; i < _info.subUIs.Count; i++){
            UIInfo info = _info.subUIs[i];
            // ----- Mark item of right menu ----- //
            if (_info.attributes !=null && _info.attributes.ContainsKey("OWNER")) {
                info.attributes ??= new();
                info.attributes["OWNER"] = _info.attributes["OWNER"];
            }
            UIBase ui = UIDraw._draw_UI(_self, info.class_type, info); // TODO: subUI.type -> subUI
            _subUIs.Add(ui); 
            _info.subUIs[i] = ui._info; // For saving
        }
    }

    async UniTaskVoid init_interactions(){
        // ----- Essential Interactions ----- //
        foreach (string interaction in essential_interactions){
            _InteractMgr._register_interaction(interaction);
        }
        // ----- Custom Interactions ----- //
        if (_info.interactions == null) return;
        // while (!_initDone) await UniTask.Delay(10);
        await _wait_init_done();
        foreach (string interaction in _info.interactions){
            _InteractMgr._register_interaction(interaction);
        }
    }

    // ---------- Extra functions for children class ----------
    public virtual void _init_begin(){} 
    public virtual void _init_done(){} 

    // ---------- Status ----------
    public virtual void _update_info(){
        _info.rotation = _self.transform.rotation;
        _info.anchorMin = _rt_self.anchorMin;
        _info.anchorMax = _rt_self.anchorMax;
        _info.pivot = _rt_self.pivot;
        _info.anchoredPosition = _rt_self.anchoredPosition;
        _info.sizeDelta = _rt_self.sizeDelta;
        _info.localScale = _self.transform.localScale;
    }

    public virtual void _register_receiver(){}

    public void _set_parent(GameObject parent=null){
        update_parent(parent).Forget();
        _update_UIMonitor(parent);
    }
    async UniTaskVoid update_parent(GameObject parent=null){
        if (parent != null) {
            _parent = parent;
            while (_rt_self == null) await UniTask.Delay(10);
            while (_rt_parent == null) await UniTask.Delay(10);
            _rt_self.SetParent(_rt_parent);
        }
        // update_UIMonitor(parent);
    }
    public virtual void _update_UIMonitor(GameObject parent){
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
        if (_info.background_key == "") {
            Image img = _self.GetComponent<Image>() ?? _self.AddComponent<Image>();
            img.color = new(0, 0, 0, 0);
        }
        else {
            Image img = _self.GetComponent<Image>() ?? _self.AddComponent<Image>();
            img.color = _info.color;
            if (_MatSys._spr._check_exist(_info.background_key)){
                while (!_MatSys._spr._check_loaded(_info.background_key)) {
                    Debug.Log("waiting for UI sprite loaded: " + _info.name + " - " + _info.background_key);
                    await UniTask.Delay(10);
                }
                img.sprite = _MatSys._spr._get_sprite(_info.background_key);
            }
            if (_info.check_PixelsPerUnitMultiplier){
                img.type = Image.Type.Sliced;
                img.pixelsPerUnitMultiplier = _info.PixelsPerUnitMultiplier;
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
        // if (_enableNavigation) 
        //     EventSystem.current.SetSelectedGameObject(_self);
        _UISys._UIMonitor._show_UI(this);
        _UISys._UIMonitor._set_UI_selected(this).Forget();
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
    public override void _destroy(){
        base._destroy();
        _UISys._UIMonitor._remove_UI_fg(this);
        _UISys._UIMonitor._remove_UI(this);
        UnityEngine.Object.Destroy(_self);
    }

    // void set_navigation(){
    //     if (!_enableNavigation) return;
    //     _self.AddComponent<Button>().transition = Selectable.Transition.None;
    //     EventSystem.current.SetSelectedGameObject(_self);
    // } 
    
    // ---------- GameObject Generate ----------
    void create_self(){ 
        if (_info.prefab_key == "" || _info.prefab_key == null) 
            create_gameObject(); 
        else 
            create_prefab().Forget(); 
    }
    void create_gameObject(){ 
        _self = new(_info.name); 
        _self.transform.SetParent(_parent.transform, false);
    }
    async UniTaskVoid create_prefab(){
        while (!_MatSys._check_all_info_initDone()) {
            Debug.Log("waiting for Material System init.");
            await UniTask.Delay(10);
        }
        if (_MatSys._UIPfb._check_exist(_info.prefab_key)){
            while (!_MatSys._UIPfb._check_loaded(_info.prefab_key)) {
                Debug.Log("waiting for UI prefab loaded: " + _info.name + " - " + _info.prefab_key);
                await UniTask.Delay(10);
            }
            GameObject obj = _MatSys._UIPfb._get_pfb(_info.prefab_key);
            _self = UnityEngine.Object.Instantiate(obj, _parent.transform);
            _self.name = _info.name;
        }
        else {
            Debug.Log("UI prefab not exist: " + _info.prefab_key);
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
        if (anchorMin != null) _info.anchorMin = anchorMin.Value;
        if (anchorMax != null) _info.anchorMax = anchorMax.Value;
        if (pivot != null) _info.pivot = pivot.Value;
        if (anchoredPosition != null) _info.anchoredPosition = anchoredPosition.Value;
        // _anchorMin = anchorMin; 
        // _anchorMax = anchorMax; 
        // _pivot = pivot; 
        // _anchoredPosition = anchoredPosition; 
    }
    public virtual void _apply_UIPosition(){
        _rt_self.anchorMin = _info.anchorMin; 
        _rt_self.anchorMax = _info.anchorMax; 
        _rt_self.pivot = _info.pivot; 
        _rt_self.anchoredPosition = _info.anchoredPosition; 
    }
    public virtual void _apply_UIShape(){
        _rt_self.sizeDelta = _info.sizeDelta;
        _self.transform.rotation = _info.rotation;
        _rt_self.localScale = _info.localScale;
    }

    public async UniTaskVoid _set_pos(Vector2 pos){
        // _disable(); // 应该能避免UI闪烁
        while (_rt_self == null) await UniTask.Yield();
        _rt_self.position = pos;
        _enable();
    }

}
