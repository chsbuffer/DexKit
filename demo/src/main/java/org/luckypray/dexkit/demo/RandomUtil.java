package org.luckypray.dexkit.demo;

import android.util.Log;

import java.util.Random;

public abstract class RandomUtil {

    public static String TAG = "RandomUtil";

    public static int getRandomDice() {
        int randValue = new Random().nextInt(6) + 1;
        Log.d(TAG, "getRandomDice: " + randValue);
        return randValue;
    }

    public static int getLiteralBinop(int value) {
        int lit16 = value + 30000;
        return lit16 ^ -7;
    }
}
