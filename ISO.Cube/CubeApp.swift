
import SwiftUI

@main
struct ISOCubeApp: App {
    var body: some Scene {
        WindowGroup {
            //ContentView()
            RotationTestView()
            /***
            ContentView()
                .environmentObject(TimerViewModel())
             **/
        }
    }
}
/***
import SwiftUI

@main
struct ISOCubeApp: App {
    @StateObject private var timerVM = TimerViewModel() // 如果 Cuberotation 需要 timerVM，可以保留

    var body: some Scene {
        WindowGroup {
            // 这里把 ContentView() 换成你新写的 Cuberotation()
            CubeRotationManager()
        }
    }
}
**/
