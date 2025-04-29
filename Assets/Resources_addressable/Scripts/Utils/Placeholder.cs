using Cysharp.Threading.Tasks;

public static class Placeholder{
    static bool notRun = false;
    public static async UniTask noAsyncWarning(){ if (notRun) await UniTask.Yield();  }
}