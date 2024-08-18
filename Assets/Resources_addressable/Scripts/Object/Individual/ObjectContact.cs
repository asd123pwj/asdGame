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
    ObjectConfig _Config;
    // ---------- Status ----------
    // ---------- Internal ----------
    
    public ObjectContact(ObjectConfig config){
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
        List<string> contact_self = _Config._tags.contact_self;
        List<string> contact_other = _Config._tags.contact_other;
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
