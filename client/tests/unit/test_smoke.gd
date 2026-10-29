extends GutTest


func test_pipeline_runs() -> void:
	var total: int = 1 + 1
	assert_eq(total, 2)
