const fs = require('fs');
let content = fs.readFileSync('E:/gamedemo1/scenes/schedule/ScheduleHub.gd', 'utf8');

// Remove emoji from _sys_button calls
const emojiMap = [
	['_sys_button("💾 存档")', '_sys_button("存档")'],
	['_sys_button("📂 读档")', '_sys_button("读档")'],
	['_sys_button("⚙ 设置")', '_sys_button("设置")'],
	['_sys_button("🏠 返回主菜单")', '_sys_button("返回主菜单")'],
];

for (const [old, nu] of emojiMap) {
	if (content.includes(old)) {
		content = content.replaceAll(old, nu);
		console.log('Replaced: ' + JSON.stringify(old));
	} else {
		console.log('Not found: ' + JSON.stringify(old));
	}
}

fs.writeFileSync('E:/gamedemo1/scenes/schedule/ScheduleHub.gd', content, 'utf8');
console.log('Done');
