#!/usr/bin/env php
<?php
define('BP_CLI_ROOT', realpath(__DIR__ . '/../'));
$composer = json_decode(file_get_contents(BP_CLI_ROOT . '/composer.json'));
$bp = new Bootpress_CLI();

switch(strtolower($argv[1])) {
	case 'setup':
		echo 'Setup' . PHP_EOL;
		break;
	case 'phplint':
		echo 'Linting the files' . PHP_EOL;
		foreach($bp->getPhpFiles() as $file) exec('php -l "' . $file . '"');
		break;
	case 'phpcs':
		echo 'Checking that files matching the WordPress coding guideline' . PHP_EOL;
		passthru('php vendor/bin/phpcs --standard=./tests/ruleset.xml src/');
		break;
	case 'phpunit':
		echo 'Running the unit tests' . PHP_EOL;
		$extra = get_current_user() === 'travis' ? ' --coverage-clover build/logs/clover.xml' : '';
		passthru('php vendor/bin/phpunit -c tests/phpunit.xml' . $extra);
		break;
	case '':
		break;
	default:
}

class Bootpress_CLI {
	public function getFiles($folder, $pattern = '/^.+\.php$/i') {
		$files = array();
		$directory = new RecursiveDirectoryIterator(BP_CLI_ROOT . '/' . $folder);
		$iterator = new RecursiveIteratorIterator($directory);

		if($pattern) {
			$iterator = new RegexIterator($iterator, $pattern, RecursiveRegexIterator::GET_MATCH);
		}

		foreach($iterator as $key => $value) {
			$files[] = $key;
		}

		return $files;
	}
	public function getPhpFiles() {
		return array_merge(
			array(BP_CLI_ROOT . '/index.php'),
			$this->getFiles('src'),
			$this->getFiles('tests')
		);
	}
}
