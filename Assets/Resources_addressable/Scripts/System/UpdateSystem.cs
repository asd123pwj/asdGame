using System.Collections.Generic;
using UnityEngine;

public delegate void UpdateAction();
public class Updater {
    BaseClass Base;
    // UpdateAction action;
    // float interval, 
    float elapsed_time;
    public Updater(BaseClass baseClass){
        this.Base = baseClass;
        elapsed_time = 0;
    }
    // public Updater(UpdateAction action, float interval){
    //     this.action = action;
    //     this.interval = interval;
    //     elapsed_time = 0;
    // }
    public void _run(float delta_time){
        // interval == 0, run action every frame
        if (Base._update_interval == 0) {
            Base._update();
            return;
        }
        // interval > 0, run action every interval
        elapsed_time += delta_time;
        if (elapsed_time >= Base._update_interval) {
            Base._update();
            elapsed_time -= Base._update_interval;
        }
    }
}

public class UpdateSystem: BaseClass{
    List<Updater> updaters = new();
    Dictionary<BaseClass, Updater> action2updater = new();

    public void Update(){
        foreach (Updater updater in updaters){
            updater._run(Time.deltaTime);
        }
    }

    public int _add_updater(BaseClass baseClass){
        Updater updater = new(baseClass);
        action2updater.Add(baseClass, updater);
        _add_updater(updater);
        return updaters.Count - 1;
    }
    // public int _add_updater(UpdateAction action, float interval){
    //     Updater updater = new(action, interval);
    //     action2updater.Add(action, updater);
    //     _add_updater(updater);
    //     return updaters.Count - 1;
    // }
    public void _add_updater(Updater updater){
        updaters.Add(updater);
    }

    // public void _remove_updater(UpdateAction action){
    //     Updater updater = action2updater[action];
    //     updaters.Remove(updater);
    //     action2updater.Remove(action);
    // }
    public void _remove_updater(BaseClass baseClass){
        Updater updater = action2updater[baseClass];
        updaters.Remove(updater);
        action2updater.Remove(baseClass);
    }
}
