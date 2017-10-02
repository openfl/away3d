package away3d.core.sort;

import away3d.core.data.RenderableListItem;
import away3d.core.traverse.EntityCollector;

/**
 * RenderableSorter sorts the potentially visible IRenderable objects collected by EntityCollector for optimal
 * rendering performance. Objects are sorted first by material, then by distance to the camera. Opaque objects
 * are sorted front to back, while objects that require blending are sorted back to front, to ensure correct
 * blending.
 */
class RenderableMergeSort implements IEntitySorter
{
	/**
	 * Creates a RenderableSorter objects
	 */
	public function new()
	{
	}
	
	/**
	 * @inheritDoc
	 */
	public function sort(collector:EntityCollector):Void
	{
		collector.opaqueRenderableHead = mergeSortByMaterial(collector.opaqueRenderableHead);
		collector.blendedRenderableHead = mergeSortByDepth(collector.blendedRenderableHead);
	}
	
	private function mergeSortByDepth(head:RenderableListItem):RenderableListItem
	{
		var headB:RenderableListItem;
		var fast:RenderableListItem, slow:RenderableListItem;
		
		if (head == null || head.next == null)
			return head;
		
		// split in two sublists
		slow = head;
		fast = head.next;
		
		while (fast != null) {
			fast = fast.next;
			if (fast != null) {
				slow = slow.next;
				fast = fast.next;
			}
		}
		
		headB = slow.next;
		slow.next = null;
		
		// recurse
		head = mergeSortByDepth(head);
		headB = mergeSortByDepth(headB);
		
		// merge sublists while respecting order
		var result:RenderableListItem = null;
		var curr:RenderableListItem = null;
		var l:RenderableListItem = null;
		
		if (head == null)
			return headB;
		if (headB == null)
			return head;
		
		while (head != null && headB != null) {
			if (head.zIndex < headB.zIndex) {
				l = head;
				head = head.next;
			} else {
				l = headB;
				headB = headB.next;
			}
			
			if (result == null)
				result = l;
			else
				curr.next = l;
			
			curr = l;
		}
		
		if (head != null)
			curr.next = head;
		else if (headB != null)
			curr.next = headB;
		
		return result;
	}
	
	private function mergeSortByMaterial(head:RenderableListItem):RenderableListItem
	{
		var headB:RenderableListItem;
		var fast:RenderableListItem, slow:RenderableListItem;
		
		if (head == null || head.next == null)
			return head;
		
		// split in two sublists
		slow = head;
		fast = head.next;
		
		while (fast != null) {
			fast = fast.next;
			if (fast != null) {
				slow = slow.next;
				fast = fast.next;
			}
		}
		
		headB = slow.next;
		slow.next = null;
		
		// recurse
		head = mergeSortByMaterial(head);
		headB = mergeSortByMaterial(headB);
		
		// merge sublists while respecting order
		var result:RenderableListItem = null;
		var curr:RenderableListItem = null;
		var l:RenderableListItem = null;
		var cmp:Int;
		
		if (head == null)
			return headB;
		if (headB == null)
			return head;
		
		while (head != null && headB != null && head != null && headB != null) {
			
			// first sort per render order id (reduces program3D switches),
			// then on material id (reduces setting props),
			// then on zIndex (reduces overdraw)
			var aid:Int = head.renderOrderId;
			var bid:Int = headB.renderOrderId;
			
			if (aid == bid) {
				var ma:Int = head.materialId;
				var mb:Int = headB.materialId;
				
				if (ma == mb) {
					if (head.zIndex < headB.zIndex)
						cmp = 1;
					else
						cmp = -1;
				} else if (ma > mb)
					cmp = 1;
				else
					cmp = -1;
			} else if (aid > bid)
				cmp = 1;
			else
				cmp = -1;
			
			if (cmp < 0) {
				l = head;
				head = head.next;
			} else {
				l = headB;
				headB = headB.next;
			}
			
			if (result == null) {
				result = l;
				curr = l;
			} else {
				curr.next = l;
				curr = l;
			}
		}
		
		if (head != null)
			curr.next = head;
		else if (headB != null)
			curr.next = headB;
		
		return result;
	}
}