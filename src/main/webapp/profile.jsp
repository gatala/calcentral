<%@ taglib tagdir="/WEB-INF/tags" prefix="tags" %>

<tags:head/>

<body class="cc-page-dashboard">
<tags:header/>
<tags:topnavigation/>
<div class="cc-container-main" role="main">
	<!-- Page specific HTML -->
	<tags:lefthandnavigation/>
	<div class="cc-container-main-right">
		<h1>My profile</h1>
		<div class="cc-container-widgets cc-top-20">
			<jsp:include page="widgets/profile/profile.html" />
		</div>
	</div>
	<!-- END Page specific HTML -->
	<br class="clearfix" />
</div>
<tags:footer/>
</body>
</html>