using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;


public delegate bool threadTask();


public class ThreadMonitor{
    public static int max_threads = 16;
    public static int num_tasks = 0;
    public static Dictionary<int, RunInThread> tasks_running = new();
    public static SortedDictionary<int, RunInThread> tasks_waiting = new();
    
    public static int _add(threadTask task){
        num_tasks += 1;
        RunInThread runInThread = new(task, num_tasks);
        tasks_waiting.Add(num_tasks, runInThread);
        _try_run(runInThread);
        // Debug.Log("running: " + tasks_running.Count + " waiting: " + tasks_waiting.Count);
        return num_tasks;
    }
    
    public static void _done(RunInThread task){
        tasks_running.Remove(task.ID);
        _try_run();
    }
    public static void _cancel(int ID){
        tasks_running[ID]._cancel();
        tasks_running.Remove(ID);
        _try_run();
    }

    public static bool _try_run(RunInThread runInThread){
        if (tasks_running.Count <= max_threads){
            tasks_running.Add(runInThread.ID, runInThread);
            tasks_waiting.Remove(runInThread.ID);
            runInThread._run();
            return true;
        }
        return false;
    }

    public static bool _try_run(){
        if (tasks_waiting.Count > 0){
            var kvp = tasks_waiting.First();
            tasks_waiting.Remove(kvp.Key);
            tasks_running.Add(kvp.Value.ID, kvp.Value);
            kvp.Value._run();
            return true;
        }
        return false;
    }
}


public class RunInThread{
    CancellationTokenSource cancellationTokenSource;
    threadTask task;
    public int ID;

    public RunInThread(threadTask task, int ID){
        this.task = task;
        this.ID = ID;
        cancellationTokenSource = new CancellationTokenSource();
    }

    public void _run(){
        run_task(cancellationTokenSource.Token).Forget();
    }

    public void _cancel(){
        cancellationTokenSource.Cancel();
    }

    async UniTaskVoid run_task(CancellationToken token){
        try{
            System.Diagnostics.Stopwatch stopwatch = new();
            stopwatch.Start();
            await UniTask.RunOnThreadPool(() => task(), cancellationToken: token);
            stopwatch.Stop();
            Debug.Log("Task completed, time: " + stopwatch.ElapsedMilliseconds);
        }
        catch (OperationCanceledException){
            Debug.Log("Task was cancelled.");
        }
        ThreadMonitor._done(this);
    }
}
