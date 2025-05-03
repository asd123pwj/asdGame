using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using System;
using System.Reflection;


public class UIInteractionManager{
    // ---------- Sub Tools ----------
    UIBase Base;
    // ---------- Interaction ----------
    // public List<UIInteractBase> _interactions = new();
    public Dictionary<string, UIInteractBase> _interactions = new();
    // ---------- Status ----------

    public UIInteractionManager(UIBase UIBase){
        Base = UIBase;
    }



    public void _enable_interaction(string type_name){
        Type type = Type.GetType(type_name);
        _enable_interaction(type);
    }
    public void _enable_interaction(UIInteractBase interaction){
        Type type = interaction.GetType();
        _enable_interaction(type);
    }
    public void _enable_interaction(Type type){
        foreach (var interaction in _interactions.Values){
            if (interaction.GetType() == type){
                interaction._enable();
            }
        }
    }


    public void _disable_interaction(string type_name){
        Type type = Type.GetType(type_name);
        _disable_interaction(type);
    }
    public void _disable_interaction(UIInteractBase interaction){
        Type type = interaction.GetType();
        _disable_interaction(type);
    }
    public void _disable_interaction(Type type){
        foreach (var interaction in _interactions.Values){
            if (interaction.GetType() == type){
                interaction._disable();
            }
        }
    }

    public void _toggle_interaction(string type_name){
        Type type = Type.GetType(type_name);
        _toggle_interaction(type);
    }
    public void _toggle_interaction(UIInteractBase interaction){
        Type type = interaction.GetType();
        _toggle_interaction(type);
    }
    public void _toggle_interaction(Type type){
        foreach (var interaction in _interactions.Values){
            if (interaction.GetType() == type){
                interaction._toggle();
            }
        }
    }


    public void _unregister_interaction(string type_name){
        Type type = Type.GetType(type_name);
        _unregister_interaction(type);
    }
    public void _unregister_interaction(UIInteractBase interaction){
        Type type = interaction.GetType();
        _unregister_interaction(type);
    }
    public void _unregister_interaction(Type type){
        foreach (var interaction in _interactions.Values){
            if (interaction.GetType() == type){
                _interactions.Remove(interaction.GetType().Name);
                
                _unregister_PointerEnter(interaction);
                _unregister_PointerExit(interaction);
                _unregister_PointerDown(interaction);
                _unregister_PointerUp(interaction);
                _unregister_PointerClick(interaction);
                _unregister_Drag(interaction);
                _unregister_Drop(interaction);
                _unregister_Scroll(interaction);
                _unregister_UpdateSelected(interaction);
                _unregister_Select(interaction);
                _unregister_Deselect(interaction);
                _unregister_Move(interaction);
                _unregister_InitializePotentialDrag(interaction);
                _unregister_BeginDrag(interaction);
                _unregister_EndDrag(interaction);
                _unregister_Submit(interaction);
                _unregister_Cancel(interaction);
                Base._Trigger._init_eventTrigger();
            }
        }
    }


    public bool _unregister_PointerEnter(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerEnter");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerEnter.Remove(interaction._PointerEnter);
            return true;
        }
        return false;
    }
    public bool _unregister_PointerExit(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerExit");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerExit.Remove(interaction._PointerExit);
            return true;
        }
        return false;
    }
    public bool _unregister_PointerDown(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerDown");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerDown.Remove(interaction._PointerDown);
            return true;
        }
        return false;
    }
    public bool _unregister_PointerUp(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerUp");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerUp.Remove(interaction._PointerUp);
            return true;
        }
        return false;
    }
    public bool _unregister_PointerClick(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerClick");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerClick.Remove(interaction._PointerClick);
            return true;
        }
        return false;
    }
    public bool _unregister_Drag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Drag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Drag.Remove(interaction._Drag);
            return true;
        }
        return false;
    }
    public bool _unregister_Drop(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Drop");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Drop.Remove(interaction._Drop);
            return true;
        }
        return false;
    }
    public bool _unregister_Scroll(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Scroll");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Scroll.Remove(interaction._Scroll);
            return true;
        }
        return false;
    }
    public bool _unregister_UpdateSelected(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_UpdateSelected");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_UpdateSelected.Remove(interaction._UpdateSelected);
            return true;
        }
        return false;
    }
    public bool _unregister_Select(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Select");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Select.Remove(interaction._Select);
            return true;
        }
        return false;
    }
    public bool _unregister_Deselect(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Deselect");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Deselect.Remove(interaction._Deselect);
            return true;
        }
        return false;
    }
    public bool _unregister_Move(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Move");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Move.Remove(interaction._Move);
            return true;
        }
        return false;
    }
    public bool _unregister_InitializePotentialDrag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_InitializePotentialDrag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_InitializePotentialDrag.Remove(interaction._InitializePotentialDrag);
            return true;
        }
        return false;
    }
    public bool _unregister_BeginDrag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_BeginDrag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_BeginDrag.Remove(interaction._BeginDrag);
            return true;
        }
        return false;
    }
    public bool _unregister_EndDrag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_EndDrag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_EndDrag.Remove(interaction._EndDrag);
            return true;
        }
        return false;
    }
    public bool _unregister_Submit(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Submit");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Submit.Remove(interaction._Submit);
            return true;
        }
        return false;
    }
    public bool _unregister_Cancel(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Cancel");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Cancel.Remove(interaction._Cancel);
            return true;
        }
        return false;
    }









    public void _register_interaction(string name){
        Type type = Type.GetType(name);
        _register_interaction(type);
    }
    public void _register_interaction(Type type){
        // object[] args = new object[] { Base._self };
        object[] args = new object[] { Base };
        UIInteractBase interaction = (UIInteractBase)Activator.CreateInstance(type, args);
        _register_interaction(interaction);
    }
    public void _register_interaction(UIInteractBase interaction){
        /*
         *  The triggerMethod of interactions should be overriden.
         *  After overriding, it will add to _Event._event_xxx, to make it work.
         */
        _interactions.Add(interaction.GetType().Name, interaction);
        _register_PointerEnter(interaction);
        _register_PointerExit(interaction);
        _register_PointerDown(interaction);
        _register_PointerUp(interaction);
        _register_PointerClick(interaction);
        _register_Drag(interaction);
        _register_Drop(interaction);
        _register_Scroll(interaction);
        _register_UpdateSelected(interaction);
        _register_Select(interaction);
        _register_Deselect(interaction);
        _register_Move(interaction);
        _register_InitializePotentialDrag(interaction);
        _register_BeginDrag(interaction);
        _register_EndDrag(interaction);
        _register_Submit(interaction);
        _register_Cancel(interaction);
        Base._Trigger._init_eventTrigger();
    }

    public bool _register_PointerEnter(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerEnter");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerEnter.Add(interaction._PointerEnter);
            return true;
        }
        return false;
    }
    public bool _register_PointerExit(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerExit");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerExit.Add(interaction._PointerExit);
            return true;
        }
        return false;
    }
    public bool _register_PointerDown(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerDown");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerDown.Add(interaction._PointerDown);
            return true;
        }
        return false;
    }
    public bool _register_PointerUp(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerUp");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerUp.Add(interaction._PointerUp);
            return true;
        }
        return false;
    }
    public bool _register_PointerClick(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_PointerClick");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_PointerClick.Add(interaction._PointerClick);
            return true;
        }
        return false;
    }
    public bool _register_Drag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Drag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Drag.Add(interaction._Drag);
            return true;
        }
        return false;
    }
    public bool _register_Drop(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Drop");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Drop.Add(interaction._Drop);
            return true;
        }
        return false;
    }
    public bool _register_Scroll(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Scroll");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Scroll.Add(interaction._Scroll);
            return true;
        }
        return false;
    }
    public bool _register_UpdateSelected(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_UpdateSelected");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_UpdateSelected.Add(interaction._UpdateSelected);
            return true;
        }
        return false;
    }
    public bool _register_Select(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Select");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Select.Add(interaction._Select);
            return true;
        }
        return false;
    }
    public bool _register_Deselect(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Deselect");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Deselect.Add(interaction._Deselect);
            return true;
        }
        return false;
    }
    public bool _register_Move(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Move");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Move.Add(interaction._Move);
            return true;
        }
        return false;
    }
    public bool _register_InitializePotentialDrag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_InitializePotentialDrag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_InitializePotentialDrag.Add(interaction._InitializePotentialDrag);
            return true;
        }
        return false;
    }
    public bool _register_BeginDrag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_BeginDrag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_BeginDrag.Add(interaction._BeginDrag);
            return true;
        }
        return false;
    }
    public bool _register_EndDrag(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_EndDrag");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_EndDrag.Add(interaction._EndDrag);
            return true;
        }
        return false;
    }
    public bool _register_Submit(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Submit");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Submit.Add(interaction._Submit);
            return true;
        }
        return false;
    }
    public bool _register_Cancel(UIInteractBase interaction){
        MethodInfo derivedMethod = interaction.GetType().GetMethod("_Cancel");
        if (derivedMethod != null && derivedMethod.IsVirtual && derivedMethod.DeclaringType != typeof(UIInteractBase)){
            Base._Event._event_Cancel.Add(interaction._Cancel);
            return true;
        }
        return false;
    }


}
