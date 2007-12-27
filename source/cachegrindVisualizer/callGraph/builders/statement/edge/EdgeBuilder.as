package cachegrindVisualizer.callGraph.builders.statement.edge
{
	import cachegrindVisualizer.callGraph.builders.Builder;
	import cachegrindVisualizer.callGraph.builders.Grouper;
	import cachegrindVisualizer.callGraph.builders.Label;
	import cachegrindVisualizer.callGraph.builders.statement.StatementBuilder;
	
	import develar.data.SqlBuilder;
	
	import flash.data.SQLResult;
	import flash.events.SQLEvent;
	
	import mx.controls.Alert;
	
	public class EdgeBuilder extends StatementBuilder
	{
		protected var previousId:uint;
		protected var previousLevel:uint;
		protected var parentsIds:Object = new Object();
		
		protected var size:Size = new Size();
		
		public function EdgeBuilder(builder:Builder)
		{
			super(builder);
			sqlBuilder.statement.itemClass = Edge;		
		}
		
		/**
		 * percentage требуется в label.edge для расчета headlabel (поэтому он не зависит от label.needPercentage)
		 */
		override public function prepare():void
		{			
			sqlBuilder.add(SqlBuilder.FIELD, 'name', 'level');
			sqlBuilder.add(SqlBuilder.FIELD, 'time', 'inclusiveTime');			
			if (builder.label.needPercentage)
			{
				sqlBuilder.add(SqlBuilder.FIELD, 'time / :onePercentage as percentage');
				sqlBuilder.add(SqlBuilder.FIELD, 'inclusiveTime / :onePercentage as inclusivePercentage');
			}
			
			if (builder.configuration.grouping == Grouper.FUNCTIONS)
			{
				sqlBuilder.add(SqlBuilder.FIELD, 'name as id');
				if (!builder.label.needPercentage)
				{
					sqlBuilder.add(SqlBuilder.FIELD, 'time / :onePercentage as percentage');
				}
			}
			else if (builder.configuration.grouping == Grouper.NO)
			{
				sqlBuilder.add(SqlBuilder.FIELD, 'left as id');
				if (!builder.label.needPercentage)
				{
					sqlBuilder.add(SqlBuilder.FIELD, 'inclusiveTime / :onePercentage as inclusivePercentage');
				}
			}
			
			sqlBuilder.add(SqlBuilder.ORDER_BY, 'left');			
			sqlBuilder.build();
			
			previousId = builder.rootNode.id;
			previousLevel = builder.treeItem.level;				
		}
		
		override protected function handleSelect(event:SQLEvent):void
		{
			var edges:String = '';
			var sqlResult:SQLResult = sqlBuilder.statement.getResult();
			for each (var edge:Edge in sqlResult.data)
			{
				if (edge.level > previousLevel)
				{
					parentsIds[edge.level] = previousId;
				}
				
				if (builder.configuration.grouping == Grouper.FUNCTIONS)
				{
					edge.sizeBase = edge.percentage;
				}
				else // Grouper.NO
				{
					edge.sizeBase = edge.inclusivePercentage;
				}					
				
				edges += parentsIds[edge.level] + ' -> ' + edge.id + ' [' + build(edge) + ']\n';
				
				previousLevel = edge.level;
				previousId = edge.id;
			}
			
			builder.fileStream.writeUTFBytes(edges);
			next(sqlResult);
		}		
		
		private function build(edge:Edge):String
		{
			var result:String = size.edge(edge) + builder.label.edge(edge);
			if (!builder.configuration.blackAndWhite)
			{
				result += builder.color.edge(edge);
			}
			return result;
		}
	}
}