using System.Collections.Generic;
using UnityEngine;

public delegate void UpdateAction();
public class Updater {
    UpdateAction action;
    float interval, elapsed_time;
    public Updater(UpdateAction action, float interval){
        this.action = action;
        this.interval = interval;
        elapsed_time = 0;
    }
    public void _run(float delta_time){
        // interval == 0, run action every frame
        if (interval == 0) {
            action();
            return;
        }
        // interval > 0, run action every interval
        elapsed_time += delta_time;
        if (elapsed_time >= interval) {
            action();
            elapsed_time -= interval;
        }
    }
}

public class UpdateSystem: BaseClass{
    List<Updater> updaters = new();

    public void Update(){
        foreach (Updater updater in updaters){
            updater._run(Time.deltaTime);
        }
    }

    public int _add_updater(UpdateAction action, float interval){
        _add_updater(new(action, interval));
        return updaters.Count - 1;
    }
    public void _add_updater(Updater updater){
        updaters.Add(updater);
    }

    // public void _update_updater(int update_order, UpdateAction action, float interval){
    //     updaters[update_order] = new(action, interval);
    // }

}
