using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectConfig{
    // ---------- System Tool ----------
    public HierarchySearch _HierSearch;
    public InputSystem _InputSys;
    public ObjectIndividual _individual;
    // ---------- Unity ----------
    public GameObject _self;
    public Rigidbody2D _rb;
    // ---------- Sub Script - Config ----------
    ObjectIdentity _Identity;
    ObjectControl _Control;
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
    

    public ObjectConfig(GameObject self, ObjectTags tags, HierarchySearch hierarchy_search, InputSystem input_base){
        // ---------- action ----------
        _HierSearch = hierarchy_search;
        _InputSys = input_base;
        
        _self = self;
        _rb = _self.GetComponent<Rigidbody2D>();

        _tags = tags;
        _max_move_speed = new Vector2(10f, 10f);
        _move_force = new Vector2(5f, 5f);

        init_sub_script();
    }

    public void _onUpdate(){
        _Contact._onUpdate();
        // _AttrMoveFloat._onUpdate();
    }

    public void _set_tags(ObjectTags tags){
        _tags = tags;
    }

    void init_sub_script(){
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
