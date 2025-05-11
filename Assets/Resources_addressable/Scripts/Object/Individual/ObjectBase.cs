using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class ObjectBase: BaseClass{
    // ---------- Status - Global ----------
    public static Dictionary<int, ObjectBase> _our = new();
    // ---------- Unity ----------
    public GameObject _self, _parent;
    public Rigidbody2D _rb;
    // ---------- Sub Script - Config ----------
    ObjectIdentity _Identity;
    // ObjectControl _Control;
    // public ObjectInfo _info;
    public ObjectConfig _cfg;
    // ---------- Sub Script - Action ----------
    public ObjectContact _Contact;
    public ObjectMove _Move;
    // ---------- Sub Script - Status ----------
    public ObjectStatusContact _StatusContact;
    public ObjectStatusMove _StatusMove;
    // ---------- Sub Script - Attribute ----------
    public ObjectAttrMoveFloat _AttrMoveFloat;
    // ---------- Config ----------
    // public ObjectTags _tags;
    // public ObjectTags _tags;
    public Vector2 _max_move_speed;
    public Vector2 _move_force;
    // bool isInit = true;
    

    public ObjectBase(GameObject parent, ObjectConfig cfg){
        // _cfg = ObjectClass._set_default(GetType().Name, cfg);
        _cfg = cfg;
        _parent = parent;
    // public ObjectBase(GameObject self, ObjectInfo info){
        // ---------- action ----------
        // _sys = hierarchy_search;
        // _InputSys = input_base;
        
        // _self = self;
        // _info = info;
        // _tags = _cfg.tags;
        _max_move_speed = new Vector2(2f, 2f);
        _move_force = new Vector2(1f, 5f);
        _our.Add(_runtimeID, this);
        // isInit = false;
        // init_sub_script();
    }

    public void _onUpdate(){
        // _Contact._onUpdate();
        // _AttrMoveFloat._onUpdate();
    }

    // public void _set_tags(ObjectTags tags){
    //     _tags = tags;
    // }

    public override bool _check_allow_init(){
        if (_cfg is null) return false;
        // if (!_MatSys._obj._check_info_initDone()) return false;
        return true;
    }

    public virtual void _init_begin(){}
    public virtual void _init_done(){}

    public override void _init(){
        _init_begin();
        create_self().Forget();
        // ---------- Sub Script - Config ----------
        _Identity = new(this);
        // _Control = new(this);
        // ---------- Sub Script - Action ----------
        _Contact = new(this);
        _Move = new(this);
        // ---------- Sub Script - Status ----------
        _StatusContact = new(this);
        _StatusMove = new(this);
        // ---------- Sub Script - Attribute ----------
        _AttrMoveFloat = new(this);
        
        _ObjSys._obj2base.Add(_self, this);
        _ObjSys._runtimeID2base.Add(_runtimeID, this);
        _enable();
        _init_done();
    }

    async UniTask _set_pos(Vector2 pos){
        while (_self == null) await UniTask.Yield();
        _self.transform.position = pos;
    }

    public void _enable(){
        _self.SetActive(true);
    }
    public void _enable(Vector2 pos){
        _set_pos(pos).Forget();
        _enable();
    }

    // ---------- GameObject Generate ----------
    async UniTask create_self(){ 
        if (_cfg.prefab_key == "" || _cfg.prefab_key == null) 
            create_gameObject(); 
        else 
            await create_prefab(); 
        _rb = _self.GetComponent<Rigidbody2D>();
        await _set_pos(_cfg.position);
    }
    void create_gameObject(){ 
        _self = new(_cfg.name); 
        _self.transform.SetParent(_parent.transform, false);
    }
    async UniTask create_prefab(){
        while (!_MatSys._check_all_info_initDone()) {
            Debug.Log("waiting for Material System init.");
            await UniTask.Delay(10);
        }
        if (_MatSys._pfb._check_exist(_cfg.prefab_key)){
            // while (!_MatSys._obj._check_prefab_loaded(_cfg.prefab_key)) {
            while (!_MatSys._pfb._check_loaded(_cfg.prefab_key)) {
                Debug.Log("waiting for UI prefab loaded: " + _cfg.name + " - " + _cfg.prefab_key);
                await UniTask.Delay(10);
            }
            // GameObject obj = _MatSys._obj._get_prefab(_cfg.class_type);
            GameObject obj = _MatSys._pfb._get_prefab(_cfg.prefab_key);
            _self = UnityEngine.Object.Instantiate(obj, _parent.transform);
            _self.name = _cfg.name;
        }
        else {
            Debug.Log("UI prefab not exist: " + _cfg.prefab_key);
        }
    }
}
