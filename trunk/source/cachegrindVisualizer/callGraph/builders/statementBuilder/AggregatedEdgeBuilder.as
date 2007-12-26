package cachegrindVisualizer.callGraph.builders.statementBuilder
{
	import cachegrindVisualizer.callGraph.builders.AggregatedEdge;
	import cachegrindVisualizer.callGraph.builders.Builder;
	import cachegrindVisualizer.callGraph.builders.Grouper;
	
	import develar.data.SqlBuilder;
	
	import flash.data.SQLResult;
	import flash.events.SQLEvent;

	public class AggregatedEdgeBuilder extends EdgeBuilder
	{
		public function AggregatedEdgeBuilder(builder:Builder)
		{
			super(builder);
			sqlBuilder.statement.itemClass = AggregatedEdge;
		}
		
		override protected function get grouped():Boolean
		{
			return true;
		}
		
		override public function prepare():void
		{
			sqlBuilder.add(SqlBuilder.FIELD, 'name', 'level');
			sqlBuilder.add(SqlBuilder.FIELD, 'parentName', 'count(*) as number', 'sum(time) as summaryTime', 'avg(time) as averageTime', 'sum(inclusiveTime) as summaryInclusiveTime', 'avg(inclusiveTime) as averageInclusiveTime', 'sum(time) / :onePercentage as summaryPercentage');
				
			if (builder.configuration.grouping == Grouper.FUNCTIONS_AND_CALLS)
			{
				sqlBuilder.add(SqlBuilder.FIELD, 'name as id');
				sqlBuilder.add(SqlBuilder.GROUP_BY, 'parentName, name');
			}
			else if (builder.configuration.grouping == Grouper.CALLS)
			{
				sqlBuilder.add(SqlBuilder.FIELD, 'namesPath as id');
				sqlBuilder.add(SqlBuilder.GROUP_BY, 'namesPath');
			}
			
			sqlBuilder.add(SqlBuilder.ORDER_BY, 'min(left)');			
			sqlBuilder.build();
			
			previousId = builder.rootNode.id;
			previousLevel = builder.treeItem.level;			
		}
		
		override protected function handleSelect(event:SQLEvent):void
		{
			var edges:String = '';
			var sqlResult:SQLResult = sqlBuilder.statement.getResult();
			for each (var edge:AggregatedEdge in sqlResult.data)
			{
				if (edge.level > previousLevel)
				{
					parentsIds[edge.level] = previousId;
				}
				
				edges += '"' + getParentId(edge) + '" -> "' + edge.id + '" [' + build(edge) + ']\n';
				
				previousLevel = edge.level;
				previousId = edge.id;
			}
			
			builder.fileStream.writeUTFBytes(edges);
			next(sqlResult);
		}
		
		private function getParentId(edge:AggregatedEdge):uint
		{
			if (builder.configuration.grouping == Grouper.FUNCTIONS_AND_CALLS)
			{
				return edge.parentName;
			}
			else if (builder.configuration.grouping == Grouper.CALLS)
			{
				return parentsIds[edge.level];
			}
			
			throw new Error();
		}
		
		private function build(aggregatedEdge:AggregatedEdge):String
		{
			var result:String = /*EdgeSize.getSize(aggregatedEdge) + */builder.label.aggregatedEdge(aggregatedEdge);
			return result;
		}		
	}
}