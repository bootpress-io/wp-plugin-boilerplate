<?php
class IndexTest extends WP_UnitTestCase {

	function testIndex() {
		$this->assertEquals( 'boilerplate', awesome() );
	}

}
