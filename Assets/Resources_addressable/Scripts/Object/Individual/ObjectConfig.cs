using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectConfig: BaseClass{
    // ---------- System Tool ----------
    // public SystemManager _sys;
    // public InputSystem _InputSys;
    // public ObjectIndividual _individual;
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
    

    public ObjectConfig(GameObject self, ObjectInfo info){
        // ---------- action ----------
        // _sys = hierarchy_search;
        // _InputSys = input_base;
        
        _self = self;
        _rb = _self.GetComponent<Rigidbody2D>();
        _info = info;
        _tags = info.tags;
        _max_move_speed = new Vector2(2f, 2f);
        _move_force = new Vector2(1f, 5f);
        // isInit = false;
        // init_sub_script();
    }

    public override void _update(){
        _Contact._onUpdate();
        // _AttrMoveFloat._onUpdate();
    }

    public void _set_tags(ObjectTags tags){
        _tags = tags;
    }

    public override bool _check_allow_init(){
        if (_info.ID is null) return false;
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
    }

}
