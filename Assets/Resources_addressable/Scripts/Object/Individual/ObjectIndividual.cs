using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using MathNet.Numerics;

public class ObjectIndividual : MonoBehaviour{
    // ---------- System Tool ----------
    HierarchySearch _HierarchySearch;
    // UISystemTmp _UI;
    InputSystem _InputBase;
    // ---------- Sub Script - Config ----------
    ObjectConfig _Config;

    // ---------- Status ----------
    public ObjectInfo _info;
    bool _isInit;


    void Start(){
        _HierarchySearch = GameObject.Find("System").GetComponent<HierarchySearch>();
        // _UI = _HierarchySearch._searchInit<UISystemTmp>("UI");
        _InputBase = _HierarchySearch._searchInit<InputSystem>("Input");

        _Config = new(gameObject, _info.tags, _HierarchySearch, _InputBase);
        _Config._individual = this;
        _isInit = true;
    }

    // Update is called once per frame
    void Update(){
        if (_isInit){
            _isInit = false;
            return;
        }
        // _update_ui();
        _Config._onUpdate();
    }

    public void _set_tags(ObjectTags tags){
        _Config._set_tags(tags);
    }

    void OnCollisionEnter2D(Collision2D collision){
        _Config._Contact._on_collision(collision, "enter");
        // _Contact._update_contact_count();
        // Debug.Log("OnCollisionEnter2D-" + _Contact._contact_count_up + "-" + _status_contact._contact_count_down + "-" + _status_contact._contact_count_left + "-" + _status_contact._contact_count_right);
    }

    void OnCollisionStay2D(Collision2D collision){
        _Config._Contact._on_collision(collision, "stay");
        // _Contact._update_contact_count();
        // Debug.Log("OnCollisionStay2D-" + _status_contact._contact_count_up + "-" + _status_contact._contact_count_down + "-" + _status_contact._contact_count_left + "-" + _status_contact._contact_count_right);
    }

    void OnCollisionExit2D(Collision2D collision){
        _Config._Contact._on_collision(collision, "exit");
        // _status_contact._update_contact_count();
        // Debug.Log("OnCollisionExit2D-" + _status_contact._contact_count_up + "-" + _status_contact._contact_count_down + "-" + _status_contact._contact_count_left + "-" + _status_contact._contact_count_right);
    }

    // public void _down_fire1(Vector2 mouse_pos){
    //     Vector2 rb2mouse = mouse_pos - _Config._rb.position;
    //     rb2mouse *= _Config._rb.rotation;
    //     _Config._Move._add_force(rb2mouse, true);
    // }

    // public void _update_ui(){
    //     string player_info = "";
    //     player_info += " RB.v" + _Config._rb.velocity;
    //     player_info += " Phy2d.gravity" + Physics2D.gravity;
    //     player_info += " RB.mass" + _Config._rb.mass;
    //     player_info += " RB.gravityScale" + _Config._rb.gravityScale;
    //     _UI._update_scrollView(player_info);
    // }

}
