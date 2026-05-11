enum WheelRewardType { jokerReveal, jokerFifty, jokerPercent }

class WheelReward {
  final WheelRewardType type;
  final String title; // UI
  const WheelReward(this.type, this.title);
}

const wheelRewards = <WheelReward>[
  WheelReward(WheelRewardType.jokerReveal, '✅ Doğruyu Göster +1'),
  WheelReward(WheelRewardType.jokerFifty,  '50/50 +1'),
  WheelReward(WheelRewardType.jokerPercent,'٪ Tahmin +1'),
];