class_name UIInteract_SwapConfig
extends UIInteractBase
## （已退役）原来只有一条 `UIInteract.swap_config`：现在"对调两项"是 `Utils.swap`，
## 两条路径直接写出来，后面接一条刷新（换的是自己那两项就 `$self`）：
##   Utils.swap "$self.config.events" "$self.config.events_2"
##   + '\vUtils.swap "$self.config.content" "$self.config.content_2"'
##   + '\v$self.refresh("content")'
## 保留本文件只是不让 .uid / 引用悬空，确认没人引用后可以整个删掉。
