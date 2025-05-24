using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;


public class ObjectContact{
    // ---------- Status ----------
    ObjectBase _Base;
    static Dictionary<string, Type> _actionTypes = new ();
    public Dictionary<string, ObjectContactBase> _actions = new ();
    
    public ObjectContact(ObjectBase config){
        _Base = config;
        init_action();
    }

    ObjectContactBase _get_action(string action_name){
        if (!_actionTypes.TryGetValue(action_name, out Type type)){
            type = Type.GetType(action_name);
            _actionTypes.Add(action_name, type);
            if (type == null){
                return null;
            }
        }
        object[] args = new object[] { _Base};
        ObjectContactBase action = (ObjectContactBase)Activator.CreateInstance(type, args);
        return action;
    } 
    
    public void init_action(){
        clear_actions();
        if (_Base._cfg.tags == null) return;
        if (!_Base._cfg.tags.TryGetValue("contact", out List<string> contacts)) return;
        foreach (var contact in contacts){
            ObjectContactBase action = _get_action(contact);
            if (action == null) {
                Debug.Log("ObjectContact: No action found for contact: " + contact);
            }
            else{
                _actions.Add(contact, action);
                _register_OnCollisionEnter2D(action);
                _register_OnCollisionExit2D(action);
                _register_OnCollisionStay2D(action);
                _register_OnTriggerEnter2D(action);
                _register_OnTriggerExit2D(action);
                _register_OnTriggerStay2D(action);
                

            }
        }
    }

    
    public bool _register_OnCollisionEnter2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnCollisionEnter2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnCollisionEnterEvent += action.OnCollisionEnter2D;
            return true;
        }
        return false;
    }
    public bool _register_OnCollisionExit2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnCollisionExit2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnCollisionExitEvent += action.OnCollisionExit2D;
            return true;
        }
        return false;
    }
    public bool _register_OnCollisionStay2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnCollisionStay2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnCollisionStayEvent += action.OnCollisionStay2D;
            return true;
        }
        return false;
    }
    public bool _register_OnTriggerEnter2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnTriggerEnter2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnTriggerEnterEvent += action.OnTriggerEnter2D;
            return true;
        }
        return false;
    }
    public bool _register_OnTriggerExit2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnTriggerExit2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnTriggerExitEvent += action.OnTriggerExit2D;
            return true;
        }
        return false;
    }
    public bool _register_OnTriggerStay2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnTriggerStay2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnTriggerStayEvent += action.OnTriggerStay2D;
            return true;
        }
        return false;
    }


    public bool _unregister_OnCollisionEnter2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnCollisionEnter2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnCollisionEnterEvent -= action.OnCollisionEnter2D;
            return true;
        }
        return false;
    }
    public bool _unregister_OnCollisionExit2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnCollisionExit2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnCollisionExitEvent -= action.OnCollisionExit2D;
            return true;
        }
        return false;
    }
    public bool _unregister_OnCollisionStay2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnCollisionStay2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnCollisionStayEvent -= action.OnCollisionStay2D;
            return true;
        }
        return false;
    }
    public bool _unregister_OnTriggerEnter2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnTriggerEnter2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnTriggerEnterEvent -= action.OnTriggerEnter2D;
            return true;
        }
        return false;
    }
    public bool _unregister_OnTriggerExit2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnTriggerExit2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnTriggerExitEvent -= action.OnTriggerExit2D;
            return true;
        }
        return false;
    }
    public bool _unregister_OnTriggerStay2D(ObjectContactBase action){
        MethodInfo derivedMethod = action.GetType().GetMethod("OnTriggerStay2D");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(ObjectContactBase)){
            _Base._colliderMono.OnTriggerStayEvent -= action.OnTriggerStay2D;
            return true;
        }
        return false;
    }

    void clear_actions(){
        foreach (var action in _actions.Values){
            _unregister_OnCollisionEnter2D(action);
            _unregister_OnCollisionExit2D(action);
            _unregister_OnCollisionStay2D(action);
            _unregister_OnTriggerEnter2D(action);
            _unregister_OnTriggerExit2D(action);
            _unregister_OnTriggerStay2D(action);
        }
        _actions.Clear();
    }
}
