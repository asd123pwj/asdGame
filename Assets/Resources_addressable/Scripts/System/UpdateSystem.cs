using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public delegate void UpdateAction();
public class Updater {
    public BaseClass Base;
    float elapsed_time;

    public Updater(BaseClass baseClass){
        Base = baseClass;
        elapsed_time = 0;
    }
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
    Dictionary<int, Updater> runtimeID2updater = new();
    SortedSet<int> priorities = new();
    Dictionary<int, List<int>> priority2runtimeID = new();

    public void Update(){
        foreach (int priority in priorities){
            foreach (int key in priority2runtimeID[priority]){
                if (!runtimeID2updater.ContainsKey(key)) continue;
                Updater updater = runtimeID2updater[key];
                updater._run(Time.deltaTime);
            }
        }
    }

    void _update_priorities(){ // no use now, I think it will useful someday
        priorities.Clear();
        foreach (int key in runtimeID2updater.Keys){
            priorities.Add(runtimeID2updater[key].Base.priority);
        }
        priority2runtimeID.Clear();
        foreach (int priority in priorities){
            priority2runtimeID[priority] = new();
            foreach (int key in runtimeID2updater.Keys){
                if (runtimeID2updater[key].Base.priority == priority) priority2runtimeID[priority].Add(key);
            }
        }
    }

    public void _add_updater(BaseClass baseClass){
        runtimeID2updater.Add(baseClass._runtimeID, new(baseClass));
        priorities.Add(baseClass.priority);
        if (!priority2runtimeID.ContainsKey(baseClass.priority)) priority2runtimeID.Add(baseClass.priority, new());
        priority2runtimeID[baseClass.priority].Add(baseClass._runtimeID);
    }

    public void _remove_updater(BaseClass baseClass){
        runtimeID2updater.Remove(baseClass._runtimeID);
        priority2runtimeID[baseClass.priority].Remove(baseClass._runtimeID);
        if (priority2runtimeID[baseClass.priority].Count == 0) priorities.Remove(baseClass.priority);
    }
}
