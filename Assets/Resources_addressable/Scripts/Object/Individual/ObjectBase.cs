using System.Collections.Generic;
using UnityEngine;

public class ObjectBase: BaseClass{
    // ---------- Status - Global ----------
    public static Dictionary<int, ObjectBase> _our = new();
    // ---------- Unity ----------
    public GameObject _self;
    public Rigidbody2D _rb;
    // ---------- Sub Script - Config ----------
    ObjectIdentity _Identity;
    ObjectControl _Control;
    public ObjectInfo _info;
    // ---------- Sub Script - Action ----------
    public ObjectContact _Contact;
    public ObjectMove _Move;
    // ---------- Sub Script - Status ----------
    public ObjectStatusContact _StatusContact;
    public ObjectStatusMove _StatusMove;
    // ---------- Sub Script - Attribute ----------
    public ObjectAttrMoveFloat _AttrMoveFloat;
    // ---------- Config ----------
    public ObjectTags _tags;
    public Vector2 _max_move_speed;
    public Vector2 _move_force;
    // bool isInit = true;
    

    public ObjectBase(GameObject self, ObjectInfo info){
        // ---------- action ----------
        // _sys = hierarchy_search;
        // _InputSys = input_base;
        
        _self = self;
        _rb = _self.GetComponent<Rigidbody2D>();
        _info = info;
        _tags = info.tags;
        _max_move_speed = new Vector2(2f, 2f);
        _move_force = new Vector2(1f, 5f);
        _our.Add(_runtimeID, this);
        // isInit = false;
        // init_sub_script();
    }

    public void _onUpdate(){
        _Contact._onUpdate();
        // _AttrMoveFloat._onUpdate();
    }

    public void _set_tags(ObjectTags tags){
        _tags = tags;
    }

    public override bool _check_allow_init(){
        if (_info.name is null) return false;
        if (!_MatSys._obj._check_info_initDone()) return false;
        return true;
    }

    public override void _init(){
        // ---------- Sub Script - Config ----------
        _Identity = new(this);
        _Control = new(this);
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
    }

}
