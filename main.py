import json
import os
import subprocess
import sys
from datetime import datetime, timedelta
import time
import signal

# 检查是否有显示环境
HAS_GUI = os.environ.get('DISPLAY') is not None

# 只在有GUI的情况下导入GTK和AppIndicator
if HAS_GUI:
    try:
        import gi
        gi.require_version('Gtk', '3.0')
        gi.require_version('AppIndicator3', '0.1')
        from gi.repository import Gtk, GLib, AppIndicator3 as AppIndicator
    except ImportError as e:
        print(f"无法导入GUI库: {e}，将以命令行模式运行")
        HAS_GUI = False

class TimerApp:
    """基础计时器功能"""
    def __init__(self):
        self.data_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "timer_data.json")
        self.load_data()
        
    def load_data(self):
        try:
            with open(self.data_file, 'r') as f:
                data = json.load(f)
                self.end_time = datetime.fromisoformat(data['end_time'])
        except:
            self.reset_timer()

    def save_data(self):
        data = {'end_time': self.end_time.isoformat()}
        with open(self.data_file, 'w') as f:
            json.dump(data, f)
    
    def reset_timer(self, widget=None):
        self.end_time = datetime.now() + timedelta(hours=12)
        self.save_data()
        print(f"计时器已重置，新的到期时间: {self.end_time.isoformat()}")
        return False
    
    def get_remaining_time(self):
        return self.end_time - datetime.now()
    
    def format_time(self, remaining):
        if remaining.total_seconds() <= 0:
            return "00:00:00"
        hours, remainder = divmod(int(remaining.total_seconds()), 3600)
        minutes, seconds = divmod(remainder, 60)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    
    def execute_cleanup_script(self):
        """到期时执行清理脚本"""
        script_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cleanup.sh")
        now = datetime.now()
        
        # 只有end_time到期才执行
        if now < self.end_time:
            return True

        # 执行清理脚本
        try:
            print("计时器到期，执行清理脚本...")
            result = subprocess.run([script_path], capture_output=True, text=True)
            print("清理操作完成")
            return result.returncode == 0
        except Exception as e:
            print(f"执行清理脚本时出错: {e}")
            return False

class IndicatorApp(TimerApp):
    """AppIndicator版本的计时器应用"""
    def __init__(self):
        super().__init__()
        
        # 创建AppIndicator
        self.indicator = AppIndicator.Indicator.new(
            "countdown-timer", 
            "appointment-soon", 
            AppIndicator.IndicatorCategory.APPLICATION_STATUS
        )
        
        # 设置状态和标签
        self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.indicator.set_label(self.format_time(self.get_remaining_time()), "")
        
        # 创建菜单
        self.menu = Gtk.Menu()
        
        # 重置选项
        reset_item = Gtk.MenuItem(label="重置计时器")
        reset_item.connect("activate", self.reset_timer)
        self.menu.append(reset_item)
        
        # 退出选项
        quit_item = Gtk.MenuItem(label="退出")
        quit_item.connect("activate", self.quit)
        self.menu.append(quit_item)
        
        self.menu.show_all()
        self.indicator.set_menu(self.menu)
        
        # 启动定时器
        self.timer_id = GLib.timeout_add(1000, self.update_timer)
        
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def reset_timer(self, widget=None):
        super().reset_timer()
        self.update_display()
        return False
    
    def update_timer(self):
        remaining = self.get_remaining_time()
        if remaining.total_seconds() <= 0:
            self.execute_cleanup_script()
            self.reset_timer()
        
        self.update_display()
        return True
        
    def update_display(self):
        remaining = self.get_remaining_time()
        self.indicator.set_label(self.format_time(remaining), "")
        return True
    
    def quit(self, widget=None):
        Gtk.main_quit()
    
    def signal_handler(self, sig, frame):
        print("\n计时器停止")
        self.quit()

class CommandLineApp(TimerApp):
    def __init__(self):
        super().__init__()
        self.running = True
        
    def run(self):
        print(f"计时器启动，到期时间: {self.end_time.isoformat()}")
        print(f"剩余时间: {self.format_time(self.get_remaining_time())}")

        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)

        try:
            while self.running:
                remaining = self.get_remaining_time()
                if remaining.total_seconds() <= 0:
                    print("\n计时器到期!")
                    self.execute_cleanup_script()
                    self.reset_timer()
                
                time.sleep(60)
                print(f"剩余时间: {self.format_time(self.get_remaining_time())}")
        except Exception as e:
            print(f"发生错误: {e}")
        finally:
            print("计时器已停止")
    
    def signal_handler(self, sig, frame):
        print("\n正在停止计时器...")
        self.running = False

def print_usage():
    print("计时器使用说明:")
    print("  python main.py [mode]")
    print("模式选项:")
    print("  indicator  - 顶部菜单栏图标模式 (默认)")
    print("  cli        - 命令行模式")
    print("  reset      - 重置计时器")
    print("  status     - 显示当前状态")

if __name__ == "__main__":
    mode = "indicator"  
    
    if len(sys.argv) > 1:
        mode = sys.argv[1].lower()
    
    timer = TimerApp()
    
    if mode == "reset":
        timer.reset_timer()
        sys.exit(0)
    elif mode == "status":
        remaining = timer.get_remaining_time()
        print(f"当前到期时间: {timer.end_time.isoformat()}")
        print(f"剩余时间: {timer.format_time(remaining)}")
        sys.exit(0)
    elif mode == "indicator" and HAS_GUI:
        app = IndicatorApp()
        Gtk.main()
    elif mode == "cli" or not HAS_GUI:
        app = CommandLineApp()
        app.run()
    else:
        print_usage()