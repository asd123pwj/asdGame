using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;


public class ObjectStatusContact{
    // ---------- Action ----------
    // ---------- Config ----------
    ObjectBase _Config;
    // ---------- Status ----------
    public bool _up         { get { return _contact_count_up > 0; } }
    public bool _down       { get { return _contact_count_down > 0; } }
    public bool _left       { get { return _contact_count_left > 0; } }
    public bool _right      { get { return _contact_count_right > 0; } }
    public bool _onGround;
    public bool _onWall     { get { return _left || _right; } }
    // ---------- Internal ----------
    Dictionary<Collision2D, int[]> _contact_count = new(); // int[4]: up, down, left, right
    int _contact_count_up, _contact_count_down, _contact_count_left, _contact_count_right;

    public ObjectStatusContact(ObjectBase config){
        _Config = config;
        _Config._StatusContact = this;
        init_action();
    }
        
    void init_action(){
        // ---------- Init ----------
        // List<string> contact_self = _Config._tags.contact_self;
        // List<string> contact_other = _Config._tags.contact_other;
        List<string> contact_self = _Config._cfg.tags.GetValueOrDefault("contact_self", new ());
        List<string> contact_other = _Config._cfg.tags.GetValueOrDefault("contact_other", new ());
        // ---------- Action default ----------
        _Config._Contact._actions_update.Add(update_contact_count);
        _Config._Contact._actions_update.Add(update_onGround_and_onFloat);
        _Config._Contact._actions_onCollision.Add(update_contact);
        // ---------- Action self ----------
        // ---------- Action other ----------
    }

    void update_contact(Collision2D collision, string method){
        int[] udlr_count = new int[4];
        foreach (ContactPoint2D contact in collision.contacts){
            Vector2 normal = contact.normal;
            if (Mathf.Abs(normal.y) > Mathf.Abs(normal.x)){
                if (normal.y < 0) udlr_count[0] += 1;
                else udlr_count[1] += 1;
            } else {
                if (normal.x < 0) udlr_count[3] += 1;
                else udlr_count[2] += 1;
            }
        }
        if (method == "enter") {
            if (_contact_count.ContainsKey(collision)) _contact_count[collision] = udlr_count;
            else _contact_count.Add(collision, udlr_count);
        }
        else if (method == "exit") _contact_count.Remove(collision);
        else _contact_count[collision] = udlr_count;
    }

    void update_contact_count(){
        _contact_count_up = _contact_count_down = _contact_count_left = _contact_count_right = 0;
        foreach(KeyValuePair<Collision2D, int[]> kvp in _contact_count){
            _contact_count_up += kvp.Value[0];
            _contact_count_down += kvp.Value[1];
            _contact_count_left += kvp.Value[2];
            _contact_count_right += kvp.Value[3];
        }
    }

    void update_onGround_and_onFloat(){
        if (_onGround && !_down){
            _onGround = false;
            foreach (var action in _Config._Contact._actions_ground2Float) action();
        }
        else if (!_onGround && _down){
            _onGround = true;
            foreach (var action in _Config._Contact._actions_float2Ground) action();
        }
    }
    
}
