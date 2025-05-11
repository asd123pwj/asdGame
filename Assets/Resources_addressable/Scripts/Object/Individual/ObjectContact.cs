using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;


public class ObjectContact{
    // ---------- Action ----------
    public List<Action<Collision2D, string>> _actions_onCollision = new();
    public List<Action> _actions_update = new();
    public List<Action> _actions_ground2Float = new();
    public List<Action> _actions_float2Ground = new();
    // ---------- Config ----------
    ObjectBase _Config;
    // ---------- Status ----------
    // ---------- Internal ----------
    
    public ObjectContact(ObjectBase config){
        _Config = config;
        _Config._Contact = this;
        init_action();
    }

    public void _onUpdate(){
        foreach (var action in _actions_update) action();
    }

    public void _on_collision(Collision2D collision, string method){
        foreach (var action in _actions_onCollision){
            action(collision, method);
        }
    }

    void init_action(){
        // ---------- init ----------
        if (_Config._cfg.tags == null) return;
        List<string> contact_self = _Config._cfg.tags.GetValueOrDefault("contact_self", new ());
        List<string> contact_other = _Config._cfg.tags.GetValueOrDefault("contact_other", new ());
        //-------------------- Action onCollision --------------------
        // ---------- action default ----------
        // ---------- action self ----------
        if (contact_self.Contains("destruction")) _actions_onCollision.Add(action_destruction);
        // ---------- action other ----------
    }



    void action_destruction(Collision2D collision, string method){
        UnityEngine.Object.Destroy(_Config._self);
    }
    
}
