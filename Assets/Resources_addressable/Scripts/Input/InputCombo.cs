using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

class ComboAction{
    // ---------- Config ----------
    List<string> combo_sequence;
    float interval;
    _input_action action;
    // ---------- Status ----------
    float last_input_time = 0;
    int combo_passed = 0;

    public ComboAction(List<string> comboSequence, _input_action action): this(comboSequence, action, 0.4f){}
    public ComboAction(List<string> comboSequence, _input_action action, float interval){
        combo_sequence = comboSequence;
        this.interval = interval;
        this.action = action;
    }

    void add_input() { combo_passed += 1; last_input_time = Time.time; }
    void clear_input() { combo_passed = 0; last_input_time = 0;}
    bool check_full(){ return combo_passed == combo_sequence.Count; }
    bool check_deadline(){ return Time.time - last_input_time > interval; }
    bool check_checkWithFirstDown() { 
        if (combo_passed == 0) {
            if (combo_sequence.Count == 1) 
                return false; // single key
            return combo_sequence[combo_passed] == combo_sequence[combo_passed + 1]; // avoid same key
        }
        else {
            return combo_sequence[combo_passed] == combo_sequence[combo_passed - 1]; // avoid same key
        }
    }
    string get_next_key(){ return combo_sequence[combo_passed]; }
    bool check_nextKeyDown(Dictionary<string, KeyInfo> keyStatus){
        if (check_checkWithFirstDown()){
            return keyStatus[get_next_key()].isFirstDown;
        }
        else{
            return keyStatus[get_next_key()].isDown;
        }
    }

    public bool _act(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (InputSystem._onEdit){
            for (int i = 0; i < combo_sequence.Count; i++){
                if (!InputStatus._input_key_availableOnEdit.Contains(combo_sequence[i])) return false;
            }
        }

        if (check_combo(keyStatus)) return action(keyPos, keyStatus); 
        else return false;
    }

    bool check_combo(Dictionary<string, KeyInfo> keyStatus){
        if (check_nextKeyDown(keyStatus)){
            if (check_deadline()) {
                clear_input();
                if (check_nextKeyDown(keyStatus)) add_input();
            }
            else add_input();
            if (check_full()){
                clear_input();
                return true;
            }
        }
        return false;
    }
}

public class InputCombo{
    // ---------- actions ----------
    Dictionary<List<string>, ComboAction> comboActions = new();
    
    public InputCombo(){}

    public void _update(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        foreach (var action in comboActions.Values){
            action._act(keyPos, keyStatus);
        }
    }

    public void _register_action(List<string> input_type, _input_action action, bool isNew=false){
        if (!comboActions.ContainsKey(input_type)) 
            comboActions.Add(input_type, new(input_type, action));
        else 
            comboActions[input_type] = new(input_type, action);
    }
}

